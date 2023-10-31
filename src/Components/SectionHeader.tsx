import React from 'react';
import {Text} from 'react-native';
import {useStyle} from '../Theme';

interface ISectionHeaderProps {
  title: string;
}

const SectionHeader = ({title}: ISectionHeaderProps) => {
  const style = useStyle();

  return <Text style={style.sectionHeaderStyle}>{title}</Text>;
};

export default SectionHeader;
