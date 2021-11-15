import React from 'react';
import FeatherIcon from 'react-native-vector-icons/Feather';
import { useTheme } from '../../Theme';

const TrashIcon = () => {
  const theme = useTheme();
  return <FeatherIcon name="trash" size={22} color={theme.colors.danger} />;
};

export default TrashIcon;
