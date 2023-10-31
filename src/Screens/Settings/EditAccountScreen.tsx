import React, {useCallback, useEffect, useLayoutEffect, useState} from 'react';
import {
  SafeAreaView,
  View,
  ScrollView,
  Text,
  StyleSheet,
  Alert,
  TouchableOpacity,
} from 'react-native';
import {Picker} from '@react-native-picker/picker';
import {useNavigation, useRoute} from '@react-navigation/native';
import {connect} from 'react-redux';

import FloatingLabelTextInput from '../../Components/FloatingLabelTextInput';

import {saveAccount, removeAccount} from '../../Redux/Actions';
import {IsAsset, AccountTypes} from '../../Models';
import {useStyle, useTheme} from '../../Theme';
import SaveIcon from '../../Components/Icons/SaveIcon';
import TrashIcon from '../../Components/Icons/TrashIcon';

const styles = StyleSheet.create({
  header: {
    flexDirection: 'row',
  },
  inner: {
    flex: 3,
    flexDirection: 'column',
    justifyContent: 'flex-start',
  },
  inner2: {
    flex: 1,
    flexDirection: 'column',
    justifyContent: 'flex-end',
    marginLeft: 32,
    marginRight: 32,
    marginBottom: 32,
    marginTop: 64 + 32,
  },
});

const defaultAccount = {
  id: undefined,
  name: '',
  provider: '',
  isAsset: IsAsset.Asset,
  accountType: AccountTypes[0].id,
};

const EditAccountScreen = ({dispatch}) => {
  const navigation = useNavigation();
  const theme = useTheme();
  const style = useStyle();
  const route = useRoute();

  const routeAccount = (route.params as any)?.account || defaultAccount;
  const [account, setAccount] = useState(routeAccount);
  const [isValid, setValid] = useState(false);

  const onSaveAccount = useCallback(() => {
    dispatch(saveAccount(account));
    navigation.goBack();
  }, [account, dispatch, navigation]);

  const onRemoveAccount = useCallback(() => {
    const onRemoveAccountConfirmed = () => {
      dispatch(removeAccount(account.id));
      navigation.goBack();
    };
    Alert.alert(
      'Remove account',
      `Are you sure you wanted to remove ${account.name}?`,
      [
        {
          text: 'Yes, Remove',
          onPress: () => onRemoveAccountConfirmed(),
          style: 'destructive',
        },
        {text: 'No'},
      ],
    );
  }, [account, dispatch, navigation]);

  useEffect(() => {
    setValid(account.name !== '');
  }, [account.name]);

  useLayoutEffect(() => {
    navigation.setOptions({
      title: `${
        account.id
          ? `Edit ${account.name}`
          : `Add ${account.isAsset === IsAsset.Asset ? 'asset' : 'liability'}`
      }`,
      headerRight: () => (
        <View style={styles.header}>
          {account.id && (
            <TouchableOpacity
              style={style.rightMargin}
              onPress={() => onRemoveAccount()}>
              <TrashIcon />
            </TouchableOpacity>
          )}
          <TouchableOpacity
            style={style.rightMargin}
            disabled={!isValid}
            onPress={() => onSaveAccount()}>
            <SaveIcon />
          </TouchableOpacity>
        </View>
      ),
    });
  }, [
    navigation,
    isValid,
    account,
    style.rightMargin,
    onRemoveAccount,
    onSaveAccount,
  ]);

  const {isAsset} = account;

  const accountTypes = AccountTypes.filter(x => x.isAsset === isAsset).map(
    (s, i) => {
      return (
        <Picker.Item
          key={i}
          value={s.id}
          label={s.name}
          color={theme.colors.primary}
        />
      );
    },
  );

  return (
    <SafeAreaView style={style.safeAreaView}>
      <ScrollView
        style={style.container}
        contentContainerStyle={style.contentContainer}>
        <View style={style.column}>
          <View style={styles.inner}>
            <FloatingLabelTextInput
              label="Account name"
              onChangeText={text => setAccount({...account, name: text})}
              value={account.name}
            />
            <FloatingLabelTextInput
              label="Provider"
              onChangeText={text => setAccount({...account, provider: text})}
              value={account.provider}
            />
            <View>
              <Text style={style.label}>Type</Text>
              <Picker
                selectedValue={account.accountType}
                onValueChange={item =>
                  setAccount({...account, accountType: item})
                }>
                {accountTypes}
              </Picker>
            </View>
          </View>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
};

export default connect()(EditAccountScreen);
