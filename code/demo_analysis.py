#!/usr/bin/env python3
"""Simple sequence analysis demo using BioPython and pandas"""

from pathlib import Path
import pandas as pd
from Bio.Seq import Seq
from Bio.SeqUtils import gc_fraction

# Setup paths
script_dir = Path(__file__).resolve().parent
out_dir = script_dir.parent / "code_out" / "demo_analysis"
out_dir.mkdir(parents=True, exist_ok=True)

# Sample sequence data
sequences = {
    "Gene_A": "ATGGCTAGCTAGCTAGCTGATCGATCGATCGATCGATCGTAG",
    "Gene_B": "ATGGGGCCCAAATTTGGGCCCAAATTTGGGCCCAAATAG",
    "Gene_C": "ATGCGCGCGATATATATCGCGCGATATATATCGCGCGTAG",
    "Gene_D": "ATGAAAAAATTTTTTTAAAAATTTTTTTAAAAATTTTAG",
    "Gene_E": "ATGGCGCGCGCGCGCGCGCGCGCGCGCGCGCGCGCGTAG",
}

# Analyze sequences
results = []
for gene_id, seq_str in sequences.items():
    seq = Seq(seq_str)
    results.append({
        'gene_id': gene_id,
        'length': len(seq),
        'gc_content': round(gc_fraction(seq) * 100, 2),
        'start_codon': str(seq[:3]),
        'stop_codon': str(seq[-3:]),
    })

# Save results
df = pd.DataFrame(results)
df.to_csv(out_dir / "sequence_analysis.csv", index=False)

print(f"Done! Results in: {out_dir}")
print(df.to_string(index=False))
