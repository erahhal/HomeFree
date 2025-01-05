import gql from 'gql-tag';

export default gql`
  query HFGetVulnerabilities {
    getVulnerabilities {
      name
      pname
      version
      derivation
      affectedBy
      whitelisted
      cves {
        cveId
        cvssv3BaseScore
        severity
        description
      }
    }
  }
`;
