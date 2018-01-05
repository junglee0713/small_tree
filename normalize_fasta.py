import sys

### Reads a multi-lined fasta 
### Returns a normalized (single-lined) fasta	

fasta_fp = sys.argv[1]
normalized_fp = sys.argv[2]

with open(fasta_fp, "r") as f:
	fasta = f.read()
	fasta = fasta.split(">")
	del fasta[0]

with open(normalized_fp, "w") as out:
	for item in fasta:
		desc, seq = item.split("\n", 1)
		desc = ">" + desc.split()[0] + "\n"
		seq = seq.replace("\n", "") + "\n"
		out.write(desc + seq)
