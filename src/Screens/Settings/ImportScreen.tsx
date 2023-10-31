import React, {useEffect, useLayoutEffect, useState} from 'react';
import {SafeAreaView, View, TextInput, TouchableOpacity} from 'react-native';
import {useNavigation} from '@react-navigation/native';
import {connect, DispatchProp} from 'react-redux';

import {importJson} from '../../Redux/Actions';
import {useStyle} from '../../Theme';
import SaveIcon from '../../Components/Icons/SaveIcon';

const ImportScreen = ({dispatch}: DispatchProp<any>) => {
  const navigation = useNavigation();
  const style = useStyle();

  const [importText, setImportText] = useState('');
  const [isValid, setValid] = useState(false);

  const onSaveImport = () => {
    dispatch(importJson(importText));
    navigation.goBack();
  };

  useEffect(() => {
    setValid(importText !== '');
  }, [importText]);

  const headerRight = React.useMemo(
    () => (
      <TouchableOpacity
        style={style.rightMargin}
        disabled={!isValid}
        onPress={() => onSaveImport()}>
        <SaveIcon />
      </TouchableOpacity>
    ),
    [],
  );

  useLayoutEffect(() => {
    navigation.setOptions({
      title: 'Import',
      headerRight,
    });
  }, [navigation, isValid]);

  return (
    <SafeAreaView style={style.safeAreaView}>
      <View style={style.column}>
        <View
          style={{
            flex: 1,
            flexDirection: 'column',
            justifyContent: 'flex-start',
          }}>
          <TextInput
            style={style.textInput}
            multiline={true}
            placeholder="Paste your json export here"
            onChangeText={text => setImportText(text)}
            value={importText}
          />
        </View>
      </View>
    </SafeAreaView>
  );
};

export default connect()(ImportScreen);
