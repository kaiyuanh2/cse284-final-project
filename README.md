# CSE 284 Final Project - Plink vs. Beagle for Relative Finding

Our final project implements an Identity-by-Descent (IBD) detection and relatedness inference 
pipeline using the LWK genotype data in Plink format (same as PS2) using Beagle based on shared segments for comparison with Plink. Our workflow is as follows:

1. Cleans genotype data by removing duplicate variants
2. Converts Plink to VCF
3. Phases halotypes using Beagle
4. Detects IBD segments using Refined IBD
5. Merges overlapping IBD segments
6. Quantifies pairwise relatedness and identifies close relatives

The analysis estimates relatedness and summarizes shared genomic segments using total shared 
megabases (Mb) as a replacement for IBD1/IBD2/pi_hat in Plink baseline from PS2.

## How to run

### Dependencies
No extra installations needed in course environment, use the checklist below to install libraries if running out of course environment:

Bash: `java`, `plink`, `bcftools`, `tabix`

Python: `pandas`, `gzip`, `matplotlib`

### Run Plink (Baseline) Pipeline
Run `bash run_plink.bash` to run the full Plink pipeline including preprocessing and IBD export.
The final output should be `lwk.ibd.nodup.genome`. Then open `plink-relative-finding.ipynb` for final relative finding and visualizations.

### Run Beagle Pipeline
Run `bash run_beagle.bash` to run the full Beagle pipeline including preprocessing, phasing, and refined IBD.
The final output should be `lwk.refined_ibd.merged.ibd.gz`. Then open `beagle-relative-finding.ipynb` for final relative finding and visualizations.

## Discussion

As a baseline, we used Plink’s built-in relatedness estimation (--genome) to identify
close relatives directly from genotype similarity (IBD1/IBD2/pi_hat). This gives us an independent, established measure of
relatedness that does not rely on phasing or IBD segment detection experienced in PS2.

In Plink pipeline, we expected IBD1=1 (pi_hat value of .50) for parent/child, IBD1=0.5, IBD2=0.25 (pi_hat value of 0.5) for full siblings. We found 4 possible parent-child pairs and 7 possible sibling pairs, same as in PS2.

For each pair (A, B), we calculated the following:

1. nseg_raw which is the number of IBD segments detected
2. total_bp_merged / total_mb_merged which are total merged shared segment lengths (in bp/Mb) across autosomes
3. mean_seg_mb_raw which is the mean segment size
4. max_seg_mb_raw which is the largest segment
5. mean_lod and max_lod score across detected segments
6. pihat_like_mb which is the total shared Mb divided by 2 divided by 3400 (assumed autosomal genome) to simulate percentage of shared genome (pi_hat) in Plink

We identify close relatives in Beagle pipeline by ranking pairs using total shared segment length. Segment statistics such as the number of segments and maximum segment length are visualized to explore potential differences between relationship types. Based on our heuristic standards, we found 2 possible parent-child pairs and 7 possible sibling pairs.

We also generated two scatter plots: total shared Mb vs number of segments AND total shared Mb vs 
maximum segment length. We noticed that first degree relatives cluster at 1200 to 1500 Mb. Sibling 
like pairs have more segments (200s-400s) than parent-child like and are large but have fragmented sharing due to recombination breaking shared regions
into smaller pieces. In contrast, parent–child pairs typically show fewer segments but much longer contiguous segments.

Our results can be found in `plink-relative-finding.ipynb` and `beagle-relative-finding.ipynb`. Comparing our Beagle + Refined IBD results to the Plink baseline is important to validate that our pipeline correctly identifies the same relative pairs and produces consistent relatedness estimates.

## Remaining Works

As far as remaining works, we will compare Plink's baseline relatedness estimates with our Beagle + Refined IBD-based relatedness metrics primarily derived from shared segment lengths. We will compare pairwise rankings and agreement between pi_hat and our Mb based assessment. This will allow us to validate our Beagle phasing + Refined IBD pipeline and also examine any discrepancies.

## Challenges
Phasing in Beagle breaks long IBD tracts into multiple segments, which we observed struggling to predict parent–child pairs with estimating pi_hat values.

## References
[Textbook 5.4: Computing expected IBD segment sharing](https://gymrek-lab.github.io/personal-genomics-textbook/ancestry/relfind/ibd_segments.html)

[Beagle 4.1](https://faculty.washington.edu/browning/beagle/beagle_4.1_21Jan17.pdf)
