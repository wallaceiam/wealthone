import * as React from 'react';
import {Text, View} from 'react-native';
import {styles} from './AboutScreen';

interface ISectionHeaderProps {
  readonly title: string;
}

export const SectionHeader = ({title}: ISectionHeaderProps) => (
  <View style={styles.sectionHeaderContainer}>
    <Text style={styles.sectionHeaderText}>{title}</Text>
  </View>
);
