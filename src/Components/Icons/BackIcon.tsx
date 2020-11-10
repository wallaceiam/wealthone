import React from 'react';
import FeatherIcon from 'react-native-vector-icons/Feather';
import { useTheme } from '../../Theme';

const BackIcon = () => {
  const theme = useTheme();
  return (
    <FeatherIcon
      name="chevron-left"
      size={24}
      color={theme.colors.primary}
    />
  );
};

export default BackIcon;
