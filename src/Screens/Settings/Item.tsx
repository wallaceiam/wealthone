import React from 'react';
import { TouchableOpacity, View, Text } from 'react-native';
import FeatherIcon from 'react-native-vector-icons/Feather';

import { useStyle } from '../../Theme';

const Item = ({ text, icon, onClick, color }) => {
  const style = useStyle();
  return (
    <TouchableOpacity onPress={onClick}>
      <View style={style.row}>
        <Text style={[style.text, style.bottomMargin]}>{text}</Text>
        {icon !== undefined ? (
          <FeatherIcon name={icon} size={16} color={color} />
        ) : null}
      </View>
    </TouchableOpacity>
  );
};

export default Item;
