import React from 'react';
import FeatherIcon from 'react-native-vector-icons/Feather';
import { useTheme } from '../../Theme';

const ForwardIcon = () => {
  const theme = useTheme();
  return (
    <FeatherIcon
      name="chevron-right"
      size={20}
      color={theme.colors.primary}
    />
  );
};

export default ForwardIcon;
