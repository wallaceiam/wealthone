import React from 'react';
import FeatherIcon from 'react-native-vector-icons/Feather';
import {useTheme} from '../../Theme';

const SaveIcon = () => {
  const theme = useTheme();
  return <FeatherIcon name="save" size={22} color={theme.colors.primary} />;
};

export default SaveIcon;
