# CSE 284 Final Project - PLINK vs. Beagle for Relative Finding

Our final project implements an Identity-by-Descent (IBD) detection and relatedness inference pipeline using the LWK genotype data from 1000 Genomes in PLINK format (same as PS2) using Beagle based on shared segments for comparison with PLINK. Our Beagle workflow is as follows:

1. Cleans genotype data by removing duplicate variants
2. Converts PLINK to VCF
3. Phases halotypes using Beagle
4. Detects IBD segments using Refined IBD
5. Merges overlapping IBD segments
6. Quantifies pairwise relatedness and identifies close relatives

The analysis estimates relatedness and summarizes shared genomic segments using genome coverage based on total shared megabases (Mb) to determine close (first-order) relatives. In addition, we manually inspected 1000 Genomes data to find ground truth relative information of sampled LWK dataset.

## How to run

### Dependencies
No extra installations needed in course environment, use the checklist below to install libraries if running out of course environment:

Bash: `java`, `plink`, `bcftools`, `tabix`

Python: `pandas`, `gzip`, `matplotlib`

### Run PLINK (Baseline) Pipeline
Run `bash run_plink.bash` to run the full PLINK pipeline including preprocessing and IBD export.
The final output should be `lwk.ibd.nodup.genome`. Then open `plink-relative-finding.ipynb` for final relative finding and visualizations.

### Run Beagle Pipeline
Run `bash run_beagle.bash` to run the full Beagle pipeline including preprocessing, phasing, and refined IBD.
The final output should be `lwk.refined_ibd.merged.ibd.gz`. Then open `beagle-relative-finding.ipynb` for final relative finding and visualizations.

## Discussion

As a baseline, we used PLINK’s built-in relatedness estimation (--genome) to identify
close relatives directly from genotype similarity (IBD1/IBD2/pi_hat). This gives us an independent, established measure of
relatedness that does not rely on phasing or IBD segment detection experienced in PS2.

In PLINK pipeline, we expected IBD1=1 (pi_hat value of .50) for parent/child, IBD1=0.5, IBD2=0.25 (pi_hat value of 0.5) for full siblings. We found 4 possible parent-child pairs and 6 possible sibling pairs, same as in PS2. We generated IBD1 vs. IBD2 graph adding identified parent/child and sibling pairs. Compared to ground truth (manually collected from 1000 Genomes website), 4 parent-child pairs match perfectly and 5 out of 6 sibling pairs matched.

We identify close (first-order) relatives in Beagle pipeline by ranking pairs using genome coverage (Divide by estimated 2.8 Gb from Chromosome 1 to 22) derived from total shared segment length. Segment statistics such as the number of shared segments and maximum shared segment length are observed to separate parent/child and sibling pairs. The top 10 close relatives exactly match all PLINK pipeline's 10 detections and covered all 9 ground truth pairs.

We generated two plots from Beagle results: one histogram exploring genome coverage data distribution of Top 1% shared segment coverage, one scatterplot of maximum shared segment length vs. number of shared IBD segments to explore how they divide parent-child pairs and sibling pairs with reference to PLINK relative finding and ground truth.

All results and visualizations can be found in `plink-relative-finding.ipynb` and `beagle-relative-finding.ipynb`. Comparing our Beagle + Refined IBD results to the PLINK pipeline is important to validate that Beagle pipeline also correctly identifies the same relative pairs and produces consistent relatedness estimates.

## Challenges
- Phasing in Beagle breaks long IBD tracts into multiple segments, with segment-level output, we observed struggling to predict parent–child pairs due to difficulties recovering IBD0/1/2 values in PLINK pipeline.
- Our observation on how maximum shared segment length and number of shared IBD segments divide parent-child and sibling pairs in Beagle pipeline is only heuristic. More evidence is needed to verify this observation.
- Beagle phasing is very slow (> 1 hr), making it much less efficient compared to PLINK pipeline for relative finding.

## Remaining Works
If we have chance to continue working on this project, we will consider adding more datasets to verify our heuristic on how maximum shared segment length and number of shared IBD segments divide parent-child and sibling pairs in Beagle pipeline, and attempt to optimize Beagle phasing or use smaller sampled portion of genome for relative finding.

## References
[Textbook 5.4: Computing expected IBD segment sharing](https://gymrek-lab.github.io/personal-genomics-textbook/ancestry/relfind/ibd_segments.html)

[Beagle 4.1](https://faculty.washington.edu/browning/beagle/beagle_4.1_21Jan17.pdf)
