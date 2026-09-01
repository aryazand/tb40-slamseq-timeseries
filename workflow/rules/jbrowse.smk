rule jbrowse_create:
    output:
        touch("results/jbrowse/create"),
        local(config["jbrowse"]["dir"] + "/index.html"),
    conda:
        "../envs/jbrowse.yml"
    params:
        jbrowse_dir=config["jbrowse"]["dir"],
    message:
        "create jbrowse folder"
    shell:
        """
        jbrowse create {params.jbrowse_dir} --force
        """


# ─────────────────────────────────────────────────────────────────────────────
# 1. Add Assembly
# ─────────────────────────────────────────────────────────────────────────────


rule faToTwoBit_fa:
    input:
        "results/genome/genome.fasta",
    output:
        "results/genome/genome.2bit",
    log:
        "results/genome/genome.fa_to_2bit.log",
    wrapper:
        "v7.1.0/bio/ucsc/faToTwoBit"


rule jbrowse_add_assembly:
    input:
        local(config["jbrowse"]["dir"] + "/index.html"),
        assembly=local("results/genome/genome.2bit"),
    output:
        touch("results/jbrowse/add_assembly"),
        local(config["jbrowse"]["dir"] + "/config.json"),
    conda:
        "../envs/jbrowse.yml"
    resources:
        file_lock=1,
    params:
        s3_url=config["jbrowse"]["s3_url"],
        jbrowse_config=config["jbrowse"]["dir"] + "/config.json",
        extra=config["jbrowse"]["add_assembly"]["extra"],
    message:
        "add genome assembly to jbrowse"
    shell:
        """
        jbrowse add-assembly {params.s3_url}/{input.assembly} --type twoBit --target {params.jbrowse_config} {params.extra} --force
        """


# ─────────────────────────────────────────────────────────────────────────────
# 2. Add Annotation
# ─────────────────────────────────────────────────────────────────────────────


rule sort_gff:
    input:
        gff="results/genome/genome.gff",
    output:
        gff="results/genome/genome.sorted.gff.gz",
    conda:
        "../envs/jbrowse.yml"
    message:
        "sort gff3"
    shell:
        """
        jbrowse sort-gff {input.gff} | bgzip >{output.gff}
        """


rule index_gff:
    input:
        "results/genome/genome.sorted.gff.gz",
    output:
        "results/genome/genome.sorted.gff.gz.tbi",
    conda:
        "../envs/jbrowse.yml"
    message:
        "index gff3"
    shell:
        """
        tabix {input}
        """


rule jbrowse_add_anno:
    input:
        local(config["jbrowse"]["dir"] + "/config.json"),
        gff=local("results/genome/genome.sorted.gff.gz"),
        gff_index="results/genome/genome.sorted.gff.gz.tbi",
    output:
        touch("results/jbrowse/add_anno"),
    conda:
        "../envs/jbrowse.yml"
    resources:
        file_lock=1,
    params:
        s3_url=config["jbrowse"]["s3_url"],
        jbrowse_config=config["jbrowse"]["dir"] + "/config.json",
        extra=config["jbrowse"]["add_anno"]["extra"],
    message:
        "add genome annotation to jbrowse"
    shell:
        """
        jbrowse add-track {params.s3_url}/{input.gff} --target {params.jbrowse_config} {params.extra}
        """


# ─────────────────────────────────────────────────────────────────────────────
# 3. Add BigWigs
# ─────────────────────────────────────────────────────────────────────────────


rule jbrowse_add_bw:
    input:
        local(config["jbrowse"]["dir"] + "/config.json"),
        bw=local("results/deeptools/coverage/{sample}.{strand}.bw"),
    output:
        touch("results/jbrowse/{sample}_{strand}_bw"),
    wildcard_constraints:
        strand="plus|minus",
        sample="|".join(samples.index),
    conda:
        "../envs/jbrowse.yml"
    resources:
        file_lock=1,
    params:
        s3_url=config["jbrowse"]["s3_url"],
        jbrowse_config=config["jbrowse"]["dir"] + "/config.json",
        extra=config["jbrowse"]["add_bw"]["extra"],
    message:
        "add bw track {wildcards.sample}_{wildcards.strand}.bw to jbrowse"
    shell:
        """
        jbrowse add-track {params.s3_url}/{input.bw} --target {params.jbrowse_config} {params.extra}
        """
