# CSE 284 Final Project Group 17 - PLINK vs. Beagle for Relative Finding

Our final project implements an Identity-by-Descent (IBD) detection and relatedness inference pipeline using the LWK genotype data from 1000 Genomes in PLINK format (same as PS2) using Beagle based on shared segments for comparison with PLINK. Our Beagle workflow is as follows:

1. Cleans genotype data by removing duplicate variants
2. Converts PLINK to VCF
3. Phases haplotypes using Beagle
4. Detects IBD segments using Refined IBD
5. Merges overlapping IBD segments
6. Quantifies pairwise relatedness and identifies close relatives

The analysis estimates relatedness and summarizes shared genomic segments using genome coverage based on total shared megabases (Mb) to determine likely close (first-degree) relatives. In addition, we manually inspected 1000 Genomes pedigree file from the project's website to retrieve ground truth relative information of sampled LWK dataset.

## How to run

### Dependencies
No extra installations needed in course environment, use the checklist below to install libraries if running out of course environment:

Bash: `java`, `plink`, `bcftools`, `tabix`

Python: `pandas`, `gzip`, `matplotlib`

### Run PLINK (Baseline) Pipeline
Run `bash ./run_plink.bash` to run the full PLINK pipeline including preprocessing and IBD export.
The final output should be `lwk.ibd.nodup.genome`. Then open `plink-relative-finding.ipynb` for final relative finding and visualizations.

### Run Beagle Pipeline
Run `bash ./run_beagle.bash` to run the full Beagle pipeline including preprocessing, phasing, and refined IBD.
The final output should be `lwk.refined_ibd.merged.ibd.gz`. Then open `beagle-relative-finding.ipynb` for final relative finding and visualizations.

\*\* `run_beagle.bash` is expected to run slowly in course datahub environment, intermediate results are provided in this repository to directly execute Python notebooks.

## Results and Discussion

As a baseline, we used PLINK’s built-in relatedness estimation (--genome) to identify
close relatives directly from genotype similarity (IBD1/IBD2/pi_hat). This gives us an independent, established measure of
relatedness that does not rely on phasing or IBD segment detection experienced in PS2.

In PLINK pipeline, we expected IBD1=1 (pi_hat value of .50) for parent/child, IBD1=0.5, IBD2=0.25 (pi_hat value of 0.5) for full siblings. We found 4 possible parent/child pairs and 6 possible sibling pairs, same as in PS2. We generated an IBD1 vs. IBD2 graph with the identified parent/child and sibling pairs highlighted. Compared to ground truth (manually collected from 1000 Genomes website), 4 parent/child pairs match perfectly and 5 out of 6 sibling pairs matched.

We identify close (first-degree) relatives in Beagle pipeline by ranking pairs using genome coverage (Divide by estimated 2.8 Gb from Chromosome 1 to 22) derived from total shared segment length. Segment statistics such as the number of shared segments and maximum shared segment length were observed heuristically to help find patterns distinguishing parent/child and sibling pairs. The top 10 pairs ranked by shared segment coverage recovered the same 10 close relative pairs identified by the PLINK pipeline and included all 9 ground truth pairs.

We generated two plots from Beagle results: one histogram exploring genome coverage data distribution of Top 1% shared segment coverage, one scatterplot of maximum shared segment length vs. number of shared IBD segments to explore how they divide parent/child pairs and sibling pairs with reference to PLINK relative finding and ground truth.

All results and visualizations can be found in `plink-relative-finding.ipynb` and `beagle-relative-finding.ipynb`. Comparing our Beagle + Refined IBD results to the PLINK pipeline is important to validate that Beagle pipeline also correctly identifies the same relative pairs and produces consistent relatedness estimates.

## Challenges
- Phasing in Beagle can break long IBD tracts into multiple segments; with only segment-level output, we found it difficult to predict parent/child pairs because the pipeline did not directly recover IBD0/1/2-style values as in PLINK.
- Our observation on how maximum shared segment length and number of shared IBD segments divide parent/child and sibling pairs in Beagle pipeline is only heuristic. More evidence is needed to verify this observation.
- Beagle phasing is very slow (1 hr 10 min) and Refined IBD takes 51 seconds, whereas PLINK `--genome` only takes 3 seconds (measured in course datahub 4 CPU + 16GB RAM), making it much less efficient compared to PLINK pipeline for relative finding.

## Remaining Works
If we had the chance to continue this project, we will consider adding more datasets to verify our heuristic on how maximum shared segment length and number of shared IBD segments divide parent/child and sibling pairs in Beagle pipeline, and attempt to optimize Beagle phasing or use smaller sampled portion of genome for relative finding.

## References

- 1000 Genomes Project. (2025, July 4). integrated_call_samples_v3.20250704.ALL.ped \[Data file]. European Bioinformatics Institute. [https://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/integrated_call_samples_v3.20250704.ALL.ped]

- 1000 Genomes Project Consortium. (2015). A global reference for human genetic variation. Nature, 526(7571), 68–74. [https://doi.org/10.1038/nature15393]

- Browning, B. L., & Browning, S. R. (2013). Improving the accuracy and efficiency of identity-by-descent detection in population data. Genetics, 194(2), 459–471. [https://doi.org/10.1534/genetics.113.150029]

- Browning, B. L., & Browning, S. R. (2017, January 21). Beagle 4.1 \[PDF]. University of Washington. [https://faculty.washington.edu/browning/beagle/beagle_4.1_21Jan17.pdf]

- Browning, B. L., & Browning, S. R. (2018, December 4). Refined IBD \[PDF]. University of Washington. [https://faculty.washington.edu/browning/refined-ibd/refined-ibd.04Dec18.pdf]

- Browning, S. R., & Browning, B. L. (2007). Rapid and accurate haplotype phasing and missing-data inference for whole-genome association studies by use of localized haplotype clustering. American Journal of Human Genetics, 81(5), 1084–1097. [https://doi.org/10.1086/521987]

- Chang, C. C., Chow, C. C., Tellier, L. C. A. M., Vattikuti, S., Purcell, S. M., & Lee, J. J. (2015). Second-generation PLINK: Rising to the challenge of larger and richer datasets. GigaScience, 4(1), Article s13742-015-0047-8. [https://doi.org/10.1186/s13742-015-0047-8]

- Huff, C. D., Witherspoon, D. J., Simonson, T. S., Xing, J., Watkins, W. S., Zhang, Y., Tuohy, T. M. F., Neklason, D. W., Burt, R. W., Guthery, S. L., Woodward, S. R., & Jorde, L. B. (2011). Maximum-likelihood estimation of recent shared ancestry (ERSA). Genome Research, 21(5), 768–774. [https://doi.org/10.1101/gr.115972.110]
