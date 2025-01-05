interface VulnixData {
  name: string;
  pname: string;
  version: string | null;
  derivation: string | null;
  cvssv3_basescore: {[key: string]: number};
  description: {[key: string]: string};
  affectedBy: string[];
  whitelisted: string[];
}

export default class Vulnerabilities {
  static async getVulnerabilities() {
    const cmd = new Deno.Command('vulnix', { args: ['--system', '--json'] });
    const { stdout } = await cmd.output();
    const jsonData = (new TextDecoder().decode(stdout)).trim();
    const data = JSON.parse(jsonData);

    const vulnerabilities = data.map((vuln: VulnixData) => {
      const cves = [];
      for (const cveId in vuln.cvssv3_basescore) {
        const score = vuln.cvssv3_basescore[cveId];
        let severity;
        if (score >= 9) {
          severity = 'CRITICAL';
        } else if (score >=7) {
          severity = 'HIGH';
        } else if (score >= 4) {
          severity = 'MEDIUM';
        } else {
          severity = 'LOW';
        }
        cves.push({
          cveId,
          cvssv3BaseScore: score,
          severity,
          description: vuln.description[cveId],
        })
      }
      return {
        name: vuln.name,
        pname: vuln.pname ?? null,
        version: vuln.version ?? null,
        derivation: vuln.derivation ?? null,
        affectedBy: vuln.affectedBy ?? [],
        whitelisted: vuln.whitelisted ?? [],
        cves: cves,
      };
    });

    return vulnerabilities;
  }
}
