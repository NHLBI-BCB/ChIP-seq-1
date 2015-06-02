# Input file 1 format: (note, gene names and GO terms can be and are duplicated, but every pairing is unique)
# Header...
# Gene_Name_1(string) GO_term(string)
# Gene_Name_2(string) GO_term(string)
# ...

# Input file 2 format:
# Header...
# GO_term (string)
# GO_term (string)
# ...

# Output file format (with NO duplications in Gene_Name):
# Header...
# Gene_Name_1 (string) 
# Gene_Name_2 (string)

if(scalar(@ARGV) != 3) { die "Usage: go2gene.pl goRequestInput gene2goInput geneOutput"; }

perl go2genes.pl gene_association GO_terms EpigGOgenes_output