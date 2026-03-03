#!/usr/bin/env bash
set -euo pipefail

# Input PLINK prefix (expects all .bed .bim .fam files)
BFILE_IN="ps2_ibd.lwk"

# Output prefixes
BFILE_NODUP="${BFILE_IN}.nodup"
VCF_PREFIX="lwk"                 # creates lwk.vcf.gz
MAP_OUT="lwk.sorted.map"         # 4 columns: CHR SNP cM BP

# Multithreading to save time
THREADS=4
MEM_GB=8

# Step 1: Remove duplicate positions (CHR:BP) — Same setting as Beagle for fairness
echo "*** Step 1: Removing duplicate CHR:BP variants from ${BFILE_IN} ***"

DUP_EXCLUDE="dup_pos.exclude.txt"
awk '
  { key=$1 ":" $4; if (seen[key]++) print $2 }
' "${BFILE_IN}.bim" > "${DUP_EXCLUDE}"

# Build de-duplicated dataset
plink --bfile "${BFILE_IN}" \
      --exclude "${DUP_EXCLUDE}" \
      --make-bed \
      --out "${BFILE_NODUP}"

echo "[Done] Wrote de-duplicated PLINK files: ${BFILE_NODUP}.bed/.bim/.fam"

# Step 2: Export IBD from PLINK
echo "*** Step 2: Exporting IBD from ${BFILE_NODUP} ***"

plink --bfile "${BFILE_NODUP}" \
      --genome \
      --out "${VCF_PREFIX}.ibd.nodup"

echo "[Done] Exported: ${VCF_PREFIX}.ibd.nodup"