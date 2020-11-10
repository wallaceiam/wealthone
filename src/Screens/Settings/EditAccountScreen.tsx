import React, { useEffect, useLayoutEffect, useState } from 'react';
import {
  SafeAreaView,
  View,
  ScrollView,
  Text,
  Button,
  StyleSheet,
  Alert,
  TouchableOpacity,
} from 'react-native';
import { Picker } from '@react-native-picker/picker';
import { useNavigation, useRoute } from '@react-navigation/native';
import { connect } from 'react-redux';

import FloatingLabelTextInput from '../../Components/FloatingLabelTextInput';

import { saveAccount, removeAccount } from '../../Redux/Actions';
import { IsAsset, AccountTypes } from '../../Models';
import { useStyle, useTheme } from '../../Theme';
import SaveIcon from '../../Components/Icons/SaveIcon';


const styles = StyleSheet.create({
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

const EditAccountScreen = ({ dispatch }) => {
  const navigation = useNavigation();
  const theme = useTheme();
  const style = useStyle();
  const route = useRoute();

  const routeAccount = route.params['account'] || defaultAccount;
  const [account, setAccount] = useState(routeAccount);
  const [isValid, setValid] = useState(false);

  const onRemoveAccountConfirmed = () => {
    dispatch(removeAccount(account.id));
    navigation.goBack();
  };

  const onSaveAccount = () => {
    dispatch(saveAccount(account));
    navigation.goBack();
  };

  const onRemoveAccount = () => {
    Alert.alert(
      'Remove account',
      `Are you sure you wanted to delete ${account.name}?`,
      [
        {
          text: 'Yes, Delete',
          onPress: () => onRemoveAccountConfirmed(),
          style: 'destructive',
        },
        { text: 'No' },
      ],
    );
  };

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
        <TouchableOpacity
          style={style.rightMargin}
          disabled={!isValid}
          onPress={() => onSaveAccount()}>
          <SaveIcon />
        </TouchableOpacity>
      ),
    });
  }, [navigation, isValid, account]);

  const { id, isAsset } = account;

  const RemoveButton = () => {
    return id !== undefined && id.length > 0 ? (
      <Button
        title="Remove account"
        color={theme.colors.danger}
        onPress={onRemoveAccount}
      />
    ) : null;
  };

  const accountTypes = AccountTypes.filter((x) => x.isAsset === isAsset).map(
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
              onChangeText={(text) => setAccount({ ...account, name: text })}
              value={account.name}
            />
            <FloatingLabelTextInput
              label="Provider"
              onChangeText={(text) =>
                setAccount({ ...account, provider: text })
              }
              value={account.provider}
            />
            <View>
              <Text style={style.label}>Type</Text>
              <Picker
                selectedValue={account.accountType}
                onValueChange={(itemValue, itemIndex) =>
                  setAccount({ ...account, accountType: itemValue })
                }>
                {accountTypes}
              </Picker>
            </View>
          </View>
          <View style={styles.inner2}>
            <RemoveButton />
          </View>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
};

export default connect()(EditAccountScreen);
