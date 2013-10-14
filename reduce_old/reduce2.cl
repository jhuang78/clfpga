#define T float
#define blockSize 128
#define nIsPow2 1

/*
    This version uses sequential addressing -- no divergence or bank conflicts.
*/
__kernel 
__attribute((reqd_work_group_size(blockSize,1,1)))
__attribute ((num_simd_work_items(2)))
__attribute ((num_compute_units(2)))
__attribute ((max_share_resources(8)))
void reduce2(__global T *g_idata, __global T *g_odata, unsigned int n, __local T* sdata)
{
    // load shared mem
    unsigned int tid = get_local_id(0);
    unsigned int i = get_global_id(0);
    
    sdata[tid] = (i < n) ? g_idata[i] : 0;
    
    barrier(CLK_LOCAL_MEM_FENCE);

    // do reduction in shared mem
	#pragma unroll
    for(unsigned int s=get_local_size(0)/2; s>0; s>>=1) 
    {
        if (tid < s) 
        {
            sdata[tid] += sdata[tid + s];
        }
        barrier(CLK_LOCAL_MEM_FENCE);
    }

    // write result for this block to global mem
    if (tid == 0) g_odata[get_group_id(0)] = sdata[0];
}
