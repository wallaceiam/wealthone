import React from 'react';
import FeatherIcon from 'react-native-vector-icons/Feather';
import { useTheme } from '../../Theme';

const SlidersIcon = () => {
  const theme = useTheme();
  return <FeatherIcon name="edit" size={24} color={theme.colors.primary} />
};

export default SlidersIcon;
