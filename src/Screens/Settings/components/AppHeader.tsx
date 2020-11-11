import React from 'react';
import { Text, View, Image, ImageStyle } from 'react-native';

import { useStyle } from '../../../Theme';

const AppHeader = () => {
  const style = useStyle();

  const manifest = {
    name: 'wealthone',
    company: 'wallace ltd',
    description: 'Your net worth tracker',
  };

  const AppIconPreview = () => {
    return (
      <Image
        source={require('../../../Assets/appicon.png')}
        style={style.appIcon as ImageStyle}
        resizeMode="cover"
      />
    );
  };

  return (
    <View style={style.appHeaderContainer}>
      <View style={style.appHeaderIconContainer}>
        <AppIconPreview />
      </View>

      <View>
        <Text style={style.nameText}>{manifest.name}</Text>

        <Text style={style.companyText}>{manifest.company}</Text>

        <Text style={style.descriptionText}>{manifest.description}</Text>
      </View>
    </View>
  );
};

export default AppHeader;
