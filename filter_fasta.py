import sys

### Reads a list of accession and the whole LTP fasta
### Returns a subset of LTP fasta based on the given list of accession

accession_fp = sys.argv[1]
ltp_fasta_fp = sys.argv[2]
out_fp = sys.argv[3]

with open(accession_fp, "r") as f:
	accession = f.read().splitlines()

with open(ltp_fasta_fp, "r") as f:
	ltp = f.read()
	ltp = ltp.split(">")
	del ltp[0]

with open(out_fp, "w") as out:
	for item in ltp:
		desc, seq = item.split("\n", 1)
		if desc in accession:
			desc = ">" + desc.split()[0] + "\n"
                	seq = seq.replace("\n", "") + "\n"
                	out.write(desc + seq)
