import gql from 'gql-tag';

export default gql`
  query HFGetServices {
    getServices {
      name
      label
      icon
    }
  }
`;
