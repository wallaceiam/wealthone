import React from 'react';
import FeatherIcon from 'react-native-vector-icons/Feather';
import { useTheme } from '../../Theme';

const PlusIcon = ({ size = 16 }) => {
  const theme = useTheme();
  return (
    <FeatherIcon
      name="plus"
      size={size}
      color={theme.colors.primary}
    />
  );
};

export default PlusIcon;
