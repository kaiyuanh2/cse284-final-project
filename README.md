# CSE 284 Final Project

Our final project implements an Identity-by-Descent (IBD) detection and relatedness inference 
pipeline using the LWK genotype data in PLINK format. Our workflow is as follows:

1. Cleans genotype data by removing duplicate variants
2. Converts PLINK to VCF
3. Phases halotypes using Beagle
4. Detects IBD segments using Refined IBD
5. Merges overlapping IBD segments
6. Quantifies pairwise relatedness and identifies close relatives

The analysis estimates relatedness and summarizes shared genomic segments using total shared 
megabases (Mb) as a replacement for PI_HAT.

## How to run

Run `run_beagle.bash` to run the full Beagle pipeline including preprocessing, phasing, and refined IBD.
The output should be lwk.refined_ibd.merged.ibd.gz.

## Discussion

As a baseline, we used PLINK’s built-in relatedness estimation (--genome to compute PI_HAT) to identify
close relatives directly from genotype similarity. This gives us an independent, established measure of
relatedness that does not rely on phasing or IBD segment detection. Comparing our Beagle + Refined IBD 
results to the PLINK baseline is important to validate that our pipeline correctly identifies the same 
relative pairs and produces consistent relatedness estimates.

Our results can be found in `beagle-relative-finding.ipynb`. 

For each pair (A, B), we calculated the following:

1. nseg_raw which is the number of IBD segments detected
2. total_mb_merged which is the total merged shared Mb across autosomes
3. mean_seg_mb_raw which is the mean segment size
4. max_seg_mb_raw which is the largest segment
5. other statistics to highlight mean and max
6. pihat_like_mb which is the total shared Mb divided by 2 divided by 3400 (assumed autosomal genome)

We expected a pi_hat value of .50 for parent/child and full siblings. A pi_hat of 0.25 for half 
siblings, and a pi_hat of 0.125 for first cousins. These are approximate estimations. 

We noticed pairs such as NA19396/NA19397 and NA19443/NA19470 to have shared Mb greater than 1400,
250+ IBD segments, and maximum segments in the mid 60s. These are classified as first degree 
relatives, most likely full siblings. 

We also generated two scatter plots: total shared Mb vs number of segments AND total shared Mb vs 
maximum segment length. We noticed that first degree relatives cluster at 1250 to 1500 Mb. Sibling 
like pairs have many segments (200-400) and are large but have fragmented sharing. Parent-child have
fewer segments but longer contiguous segments. 

We noticed the overall dataset had multiple clear first degree families and several second degree
relationships. There was also a long tail of distant relatedness. 

## Remaining Works

As far as remaining works, we will compare PLINK's baseline relatedness estimates and our IBD based 
relatedness metrics. These are primarily derived from merged segment lengths. We will compare pairwise 
rankings, degree classifications, and agreement between pi_hat and our Mb based assessment. This will
allow us to validate our phasing + Refined IBD pipeline and also examine any discrepancies. 
