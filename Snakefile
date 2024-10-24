# Defining samples and reads
samples = ["sample_name"]
reads = ["1", "2"]

# Rule defining the final output files of the workflow
rule all:
    input:
        expand("result/1.fastqc/{sample}_{read}.fastqc.zip", 
               sample=samples, read=reads),
        expand("result/1.fastqc/{sample}_{read}.fastqc.html",
               sample=samples, read=reads),
        expand("result/3.kallisto/{sample}", 
               sample=samples)

# Rule 1: FastQC on raw reads (runs in parallel for _1 and _2)
rule fastqc_raw:
    input:
        "result/0.data/{sample}_{read}.fastq.gz"
    output:
        "result/1.fastqc/{sample}_{read}.fastqc.zip",
        "result/1.fastqc/{sample}_{read}.fastqc.html"
    shell:
        "fastqc {input} --outdir=result/1.fastqc/"

# Rule 2: Trim Galore - trimming reads + FastQC
rule Trim_Galore:
    input:
        f1="result/0.data/{sample}_1.fastq.gz",
        f2="result/0.data/{sample}_2.fastq.gz"
    resources:
        mem_mb=8000, threads=8
    output:
        "result/2.trimming/{sample}_1_val_1.fq.gz",
        "result/2.trimming/{sample}_2_val_2.fq.gz"
    shell:
        """
        trim_galore --fastqc --paired {input.f1} {input.f2} \
        -o result/2.trimming/
        """

# Rule 3: Quantifying abundances of transcripts with Kallisto
rule Kallisto:
    input:
        f1="result/2.trimming/{sample}_1_val_1.fq.gz",
        f2="result/2.trimming/{sample}_2_val_2.fq.gz"
    params:
        reference="/cDNA/Homo_sapiens.GRCh38.cdna.idx"
    output:
        "result/3.kallisto/{sample}"
    resources:
        mem_mb=8000, threads=12
    shell:
        """
        kallisto quant -i {params.reference} -o {output} -b 100 -t {resources.threads} --plaintext {input.f1} {input.f2}
        """
