/*
other things we should test:
- struct pointer, with offset
- multiple struct pointers, cut from same buffer
- getting values from various types of structs passed in
*/

#include <iostream>
#include <memory>
#include <cassert>

using namespace std;

#include <cuda.h>

struct Struct_fp_fp_f_f {
    float *p1;
    float *p2;
    float f1;
    float f2;
};

struct Struct_fp {
    float *p1;
};

struct Struct_1float {
    float f1;
};

struct Struct_2floats {
    float f1;
    float f2;
};

__global__ void struct_byvalue(struct Struct_fp_fp_f_f mystruct, float *out) {
    out[0] = mystruct.f1;
    out[1] = mystruct.f2;
    mystruct.p1[0] = 9.0f;
    mystruct.p2[0] = 10.0f;
}

void testbyvaluestruct() {
    int N = 1024;

    CUstream stream;
    cuStreamCreate(&stream, 0);

    float *gpuFloats1;
    cudaMalloc((void**)(&gpuFloats1), N * sizeof(float));

    float *gpuFloats2;
    cudaMalloc((void**)(&gpuFloats2), N * sizeof(float));

    float *gpuFloats3;
    cudaMalloc((void**)(&gpuFloats3), N * sizeof(float));

    float *gpuOut;
    cudaMalloc((void**)(&gpuOut), N * sizeof(float));

    float *hostFloats1 = new float[N];
    float *hostFloats2 = new float[N];
    float *hostFloats3 = new float[N];
    float *hostOut = new float[N];

    struct Struct_fp_fp_f_f mystruct = {(float *)gpuFloats1, (float *)gpuFloats2, 3.0f, 8.0f};
    struct_byvalue<<<dim3(1,1,1), dim3(32,1,1), 0, stream>>>(mystruct, (float *)gpuOut);

    cudaMemcpy(hostFloats1, gpuFloats1, 4 * sizeof(float), cudaMemcpyDeviceToHost);
    cudaMemcpy(hostFloats2, gpuFloats2, 4 * sizeof(float), cudaMemcpyDeviceToHost);
    cudaMemcpy(hostOut, gpuOut, 4 * sizeof(float), cudaMemcpyDeviceToHost);

    cuStreamSynchronize(stream);

    cout << hostFloats1[0] << endl;
    cout << hostFloats2[0] << endl;
    cout << hostOut[0] << endl;
    cout << hostOut[1] << endl;

    assert(hostFloats1[0] == 9);
    assert(hostFloats2[0] == 10);
    assert(hostOut[0] == 3);
    assert(hostOut[1] == 8);

    cudaFree(gpuFloats1);
    cudaFree(gpuFloats2);
    cudaFree(gpuFloats3);
    cudaFree(gpuOut);

    delete[]hostFloats1;
    delete[]hostFloats2;
    delete[]hostFloats3;
    delete[]hostOut;

    cuStreamDestroy(stream);
}

__global__ void struct_aspointer(struct Struct_2floats *mystruct, float *out) {
    out[0] = mystruct->f1;
    out[1] = mystruct->f2;
}

void testaspointerstruct() {
    int N = 1024;

    CUstream stream;
    cuStreamCreate(&stream, 0);

    float *hostOut = new float[N];

    float *gpuOut;
    cudaMalloc((void**)(&gpuOut), N * sizeof(float));

    struct Struct_2floats mystruct = { 5, 7 };
    struct Struct_2floats *gpu_mystruct;
    cudaMalloc((void**)(&gpu_mystruct), sizeof(mystruct));
    cudaMemcpy(gpu_mystruct, &mystruct, sizeof(mystruct), cudaMemcpyHostToDevice);

    struct_aspointer<<<dim3(1,1,1), dim3(32,1,1), 0, stream>>>(gpu_mystruct, gpuOut);

    cudaMemcpy(hostOut, gpuOut, 4 * sizeof(float), cudaMemcpyDeviceToHost);

    cuStreamSynchronize(stream);

    cout << hostOut[0] << endl;
    cout << hostOut[1] << endl;

    assert(hostOut[0] == 5);
    assert(hostOut[1] == 7);

    delete[]hostOut;

    cuStreamDestroy(stream);
}

__global__ void kernel_twostructs(struct Struct_fp_fp_f_f mystruct, struct Struct_fp mystruct2) {
    mystruct.p1[0] = 9.0f;
    mystruct.p2[0] = 10.0f;
    mystruct2.p1[0] = 11.0f;
}

void testtwostructs() {
    int N = 1024;

    CUstream stream;
    cuStreamCreate(&stream, 0);

    float *gpuFloats1;
    cudaMalloc((void**)(&gpuFloats1), N * sizeof(float));

    float *gpuFloats2;
    cudaMalloc((void**)(&gpuFloats2), N * sizeof(float));

    float *gpuFloats3;
    cudaMalloc((void**)(&gpuFloats3), N * sizeof(float));

    float *hostFloats1 = new float[N];
    float *hostFloats2 = new float[N];
    float *hostFloats3 = new float[N];

    struct Struct_fp_fp_f_f mystruct = {(float *)gpuFloats1, (float *)gpuFloats2};
    struct Struct_fp mystruct2 = {(float *)gpuFloats3};

    kernel_twostructs<<<dim3(1,1,1), dim3(32,1,1), 0, stream>>>(mystruct, mystruct2);

    cudaMemcpy(hostFloats1, gpuFloats1, 4 * sizeof(float), cudaMemcpyDeviceToHost);
    cudaMemcpy(hostFloats2, gpuFloats2, 4 * sizeof(float), cudaMemcpyDeviceToHost);
    cudaMemcpy(hostFloats3, gpuFloats3, 4 * sizeof(float), cudaMemcpyDeviceToHost);

    cuStreamSynchronize(stream);

    cout << hostFloats1[0] << endl;
    cout << hostFloats2[0] << endl;
    cout << hostFloats3[0] << endl;

    assert(hostFloats1[0] == 9);
    assert(hostFloats2[0] == 10);
    assert(hostFloats3[0] == 11);

    cudaFree(gpuFloats1);
    cudaFree(gpuFloats2);
    cudaFree(gpuFloats3);

    delete[]hostFloats1;
    delete[]hostFloats2;
    delete[]hostFloats3;

    cuStreamDestroy(stream);
}

// __global__ void kernel_structbyval_noptrs(struct Struct_1float mystruct1, float *out) {
//     if(threadIdx.x == 0) {
//         out[0] = mystruct1.p1;
//         out[1] = 5;
//     }
// }

// void teststructbyvalNoPtr() {
//     int N = 1024;

//     CUstream stream;
//     cuStreamCreate(&stream, 0);

//     float *hostFloats1 = new float[N];

//     float *gpuFloats1;
//     cudaMalloc((void**)(&gpuFloats1), N * sizeof(float));

//     struct Struct_1float mystruct1 = {8.0f};

//     kernel_structbyval_noptrs<<<dim3(1,1,1), dim3(32,1,1), 0, stream>>>(mystruct1, (float *)gpuFloats1);

//     cudaMemcpy(hostFloats1, gpuFloats1, 4 * sizeof(float), cudaMemcpyDeviceToHost);
//     cuStreamSynchronize(stream);

//     cout << hostFloats1[0] << endl;
//     cout << hostFloats1[1] << endl;

//     assert(hostFloats1[0] == 8);

//     delete[] hostFloats1;
//     cudaFree(gpuFloats1);

//     cuStreamDestroy(stream);
// }

// __global__ void kernel_struct2byval_noptrs(struct Struct_fpNoPtr mystruct1, float *out) {
//     if(threadIdx.x == 0) {
//     out[0] = mystruct1.p1;
//     out[1] = mystruct1.p2;
//     }
// }

// void teststruct2byvalNoPtr() {
//     int N = 1024;

//     CUstream stream;
//     cuStreamCreate(&stream, 0);

//     float *hostFloats1;
//     cuMemHostAlloc((void **)&hostFloats1, N * sizeof(float), CU_MEMHOSTALLOC_PORTABLE);

//     CUdeviceptr gpuFloats1;
//     cuMemAlloc(&gpuFloats1, N * sizeof(float));
//     cuMemcpyHtoDAsync((CUdeviceptr)(((float *)gpuFloats1)), hostFloats1, N * sizeof(float), stream);

//     struct Struct_fpNoPtr mystruct1 = {8.0f, 9.0f};

//     kernel_struct2byval_noptrs<<<dim3(1,1,1), dim3(32,1,1), 0, stream>>>(mystruct1, (float *)gpuFloats1);
//     cuMemcpyDtoHAsync(hostFloats1, gpuFloats1, N * sizeof(float), stream);
//     cuStreamSynchronize(stream);

//     cout << hostFloats1[0] << endl;
//     cout << hostFloats1[1] << endl;

//     assert(hostFloats1[0] == 8);
//     assert(hostFloats1[1] == 9);

//     cuMemFreeHost(hostFloats1);
//     cuMemFree(gpuFloats1);

//     cuStreamDestroy(stream);
// }

__global__ void kernel_twostructs_noptrs(struct Struct_2floats *mystruct, struct Struct_1float *mystruct2, struct Struct_1float mystruct3, float *out) {
    if(threadIdx.x == 0) {
    out[0] = mystruct->f1;
    out[1] = mystruct->f2;
    out[2] = mystruct2->f1;
    out[3] = mystruct3.f1;
    }
}

void test_twostructs_byptr_NoPtr() {
    int N = 1024;

    CUstream stream;
    cuStreamCreate(&stream, 0);

    float *hostFloats1 = new float[N];

    float *gpuFloats1;
    cudaMalloc((void**)(&gpuFloats1), N * sizeof(float));

    struct Struct_2floats mystruct = {5.0f, 6.0f};
    struct Struct_1float mystruct2 = {7.0f};
    struct Struct_1float mystruct3 = {8.0f};

    struct Struct_2floats *gpu_mystruct;
    cudaMalloc((void**)(&gpu_mystruct), sizeof(mystruct));
    cudaMemcpy(gpu_mystruct, &mystruct, sizeof(mystruct), cudaMemcpyHostToDevice);

    struct Struct_1float *gpu_mystruct2;
    cudaMalloc((void**)(&gpu_mystruct2), sizeof(mystruct2));
    cudaMemcpy(gpu_mystruct2, &mystruct2, sizeof(mystruct2), cudaMemcpyHostToDevice);

    kernel_twostructs_noptrs<<<dim3(1,1,1), dim3(32,1,1), 0, stream>>>(gpu_mystruct, gpu_mystruct2, mystruct3, (float *)gpuFloats1);
    cudaMemcpy(hostFloats1, gpuFloats1, 4 * sizeof(float), cudaMemcpyDeviceToHost);
    cuStreamSynchronize(stream);

    cout << hostFloats1[0] << endl;
    cout << hostFloats1[1] << endl;
    cout << hostFloats1[2] << endl;
    cout << hostFloats1[3] << endl;

    assert(hostFloats1[0] == 5);
    assert(hostFloats1[1] == 6);
    assert(hostFloats1[2] == 7);
    assert(hostFloats1[3] == 8);

    cudaFree(gpuFloats1);
    cudaFree(gpu_mystruct);
    cudaFree(gpu_mystruct2);
    // cudaFree(gpu_mystruct3);

    delete[] hostFloats1;

    cuStreamDestroy(stream);
}

int main(int argc, char *argv[]) {
    cout << "\ntestvaluestruct" << endl;
    testbyvaluestruct();

    cout << "\ntestaspointersstruct" << endl;
    testaspointerstruct();

    cout << "\ntesttwostructs" << endl;
    testtwostructs();

    // cout << "\teststruct2byvalNoPtr" << endl;
    // teststruct2byvalNoPtr();

    // cout << "\teststructbyvalNoPtr" << endl;
    // teststructbyvalNoPtr();

    cout << "\ntest_twostructs_byptr_NoPtr" << endl;
    test_twostructs_byptr_NoPtr();

    return 0;
}