#include <cstdio>
#include "cpu.h"

#include "common.h"

namespace StreamCompaction {
    namespace CPU {
        using StreamCompaction::Common::PerformanceTimer;
        PerformanceTimer& timer()
        {
            static PerformanceTimer timer;
            return timer;
        }

        /**
         * CPU scan (prefix sum).
         * For performance analysis, this is supposed to be a simple for loop.
         * (Optional) For better understanding before starting moving to GPU, you can simulate your GPU scan in this function first.
         */
        void scan(int n, int *odata, const int *idata) {
            timer().startCpuTimer();
            odata[0] = 0;
            for (int i = 1; i < n; i++) {
                odata[i] = odata[i - 1] + idata[i - 1];
            }
            timer().endCpuTimer();
        }

        /**
         * CPU stream compaction without using the scan function.
         *
         * @returns the number of elements remaining after compaction.
         */
        int compactWithoutScan(int n, int *odata, const int *idata) {
            timer().startCpuTimer();
            int idx = 0;
            for (int i = 0; i < n; i++) {
                if (idata[i]) {
                    odata[idx++] = idata[i];
                }
            }
            timer().endCpuTimer();
            return idx;
        }

        /**
         * CPU stream compaction using scan and scatter, like the parallel version.
         *
         * @returns the number of elements remaining after compaction.
         */
        int compactWithScan(int n, int *odata, const int *idata) {
            timer().startCpuTimer();
            int* bools = new int[n];
            for (int i = 0; i < n; i++) {
                bools[i] = idata[i] ? 1 : 0;
            }
            int* indices = new int[n];
            indices[0] = 0;
            for (int i = 1; i < n; i++) {
                indices[i] = indices[i - 1] + bools[i - 1];
            }
            for (int i = 0; i < n; i++) {
                if (bools[i]) {
                    odata[indices[i]] = idata[i];
                }
            }
            int count = bools[n - 1] + indices[n - 1];
            delete[] bools;
            delete[] indices;
            timer().endCpuTimer();
            return count;
        }
        
        int compare(const void *a, const void *b) {
            return (*(int*)a - *(int*)b);
        }

        void sort(int n, int *odata, const int *idata) {
            timer().startCpuTimer();
            memcpy(odata, idata, n * sizeof(int));
            qsort(odata, n, sizeof(int), compare);
            timer().endCpuTimer();
        }
    }
}
