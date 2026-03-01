#!/usr/bin/env bash
set -euo pipefail

# Input PLINK prefix (expects all .bed .bim .fam files)
BFILE_IN="ps2_ibd.lwk"

# Output prefixes
BFILE_NODUP="${BFILE_IN}.nodup"
VCF_PREFIX="lwk"                 # creates lwk.vcf.gz
MAP_OUT="lwk.sorted.map"         # 4 columns: CHR SNP cM BP
PHASED_PREFIX="lwk.phased"       # creates lwk.phased.vcf.gz
REFINED_IBD_PREFIX="lwk.refined_ibd"

# Multithreading to save time
THREADS=4
MEM_GB=8

# Beagle/RefinedIBD jar files
BEAGLE_JAR="beagle.jar"
REFINED_IBD_JAR="refined-ibd.jar"
MERGE_IBD_JAR="merge-ibd-segments.jar"
MERGE_IBD_URL="https://faculty.washington.edu/browning/refined-ibd/merge-ibd-segments.17Jan20.102.jar"

# Environment Check
need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Missing required command: $1" >&2; exit 1; }; }

need_cmd plink
need_cmd awk
need_cmd sort
need_cmd bgzip
need_cmd tabix
need_cmd java
need_cmd wget

if [[ ! -f "$MERGE_IBD_JAR" ]]; then
  echo "*** merge-ibd-segments.jar not found — downloading ***"
  wget -O "$MERGE_IBD_JAR" "$MERGE_IBD_URL"
fi

[[ -f "$MERGE_IBD_JAR" ]] || { echo "Failed to obtain $MERGE_IBD_JAR"; exit 1; }

# Step 1: Remove duplicate positions (CHR:BP) — Avoid Beagle rejection
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

# Step 2: Export VCF from PLINK + index
echo "*** Step 3: Exporting bgzipped VCF from ${BFILE_NODUP} ***"

plink --bfile "${BFILE_NODUP}" \
      --recode vcf bgz \
      --out "${VCF_PREFIX}"

tabix -p vcf "${VCF_PREFIX}.vcf.gz"
echo "[Done] VCF created and indexed: ${VCF_PREFIX}.vcf.gz"

# Step 4: Build sorted PLINK-style map file for Beagle/IBD
# Format: CHR SNP cM BP (from .bim columns 1,2,3,4) sorted by CHR then BP
echo "*** Step 4: Building sorted map file ${MAP_OUT} ***"

awk 'BEGIN{OFS="\t"} {print $1,$2,$3,$4}' "${BFILE_NODUP}.bim" \
  | sort -k1,1n -k4,4n > "${MAP_OUT}"

echo "[Done] Map created: ${MAP_OUT}"

# Step 5: Phasing with Beagle (no imputation)
echo "*** Step 5: Phasing with Beagle ***"

java -Xmx"${MEM_GB}g" -jar "${BEAGLE_JAR}" \
  gt="${VCF_PREFIX}.vcf.gz" \
  map="${MAP_OUT}" \
  out="${PHASED_PREFIX}" \
  impute=false \
  nthreads="${THREADS}"

# Beagle should produce: ${PHASED_PREFIX}.vcf.gz
if [[ -f "${PHASED_PREFIX}.vcf.gz" ]]; then
  tabix -p vcf "${PHASED_PREFIX}.vcf.gz" || true
  echo "[Done] Phased VCF: ${PHASED_PREFIX}.vcf.gz"
else
  echo "[Error] Expected phased VCF not found: ${PHASED_PREFIX}.vcf.gz" >&2
fi

# Step 6: Run Refined IBD (defaults)
echo "*** Step 6: Running Refined IBD ***"

java -Xmx"${MEM_GB}g" -jar "${REFINED_IBD_JAR}" \
  gt="${PHASED_PREFIX}.vcf.gz" \
  map="${MAP_OUT}" \
  out="${REFINED_IBD_PREFIX}"

echo "[Done] Refined IBD output: ${REFINED_IBD_PREFIX}.*"
echo "All Done"

# Step 7: Merge IBD segments
echo "*** Step 7: Merging IBD segments ***"

MERGED_PREFIX="${REFINED_IBD_PREFIX}.merged"

zcat "${REFINED_IBD_PREFIX}.ibd.gz" | \
java -Xmx"${MEM_GB}g" -jar "${MERGE_IBD_JAR}" \
  "${PHASED_PREFIX}.vcf.gz" \
  "${MAP_OUT}" \
  0.6 \
  1 \
> "${MERGED_PREFIX}.ibd"

# Compress merged output
gzip -f "${MERGED_PREFIX}.ibd"

if [[ -f "${MERGED_PREFIX}.ibd.gz" ]]; then
  echo "[Done] Merged IBD output: ${MERGED_PREFIX}.ibd.gz"
else
  echo "[Error] Merged IBD file not found!" >&2
  exit 1
fi
