import React from 'react';
import { ScrollView, StyleSheet } from 'react-native';
import FeatherIcon from 'react-native-vector-icons/Feather';

export default class BlankScreen extends React.Component {
  static navigationOptions = {
    title: 'Blank',
    headerBackTitle: null,
    headerBackImage: <FeatherIcon name="chevron-left" size={24} />
  };

  render() {
    return (
      <ScrollView style={styles.container}>
        
      </ScrollView>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingTop: 15,
    backgroundColor: '#fff',
  },
});
