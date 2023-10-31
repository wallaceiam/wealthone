import React from 'react';
import {TouchableOpacity, View, Text} from 'react-native';

import {useStyle} from '../Theme';
import PlusIcon from './Icons/PlusIcon';

interface ISectionFooterProps {
  text: string;
  onClick: () => void;
}

const SectionFooter = ({text, onClick}: ISectionFooterProps) => {
  const style = useStyle();
  return (
    <TouchableOpacity onPress={onClick}>
      <View style={style.row}>
        <Text style={[style.bottomMargin, style.text, style.active]}>
          {text}
        </Text>
        <PlusIcon size={20} />
      </View>
    </TouchableOpacity>
  );
};

export default SectionFooter;
