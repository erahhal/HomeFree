import gql from 'gql-tag';

export default gql`
  mutation HFSetConfig {
    setConfig(
      file
      attribute
      value
    )
  }
`;

