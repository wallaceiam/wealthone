import React from 'react';
import { SafeAreaView, SectionList } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { connect } from 'react-redux';

import { useStyle } from '../../Theme';

import { backup, restore, update } from '../../Redux/Actions';
import { IsAsset } from '../../Models/Account';
import { SectionFooter, SectionHeader } from '../../Components';
import MenuItem from './components/MenuItem';
import AppHeader from './components/AppHeader';
import { getAssetAccounts, getLiabilityAccounts } from '../../Redux/Selectors';

const AccountName = ({ name, provider }) => {
  return (
    (name !== '' ? name : '') +
    (provider !== '' && provider !== undefined && provider !== null
      ? ` - ${provider}`
      : '')
  );
};

const SettingsScreen = ({ assets, liabilities, dispatch }) => {
  const navigation = useNavigation();
  const style = useStyle();
  const sections = [
    {
      data: assets,
      title: 'Assets',
      addFooter: true,
    },
    {
      data: liabilities,
      title: 'Liabilities',
      addFooter: true,
    },
    {
      data: [
        { action: 'backup', title: 'Backup to iCloud', icon: 'upload-cloud' },
        { action: 'restore', title: 'Restore data', icon: 'download-cloud' },
        { action: 'export', title: 'Export' },
        { action: 'import', title: 'Import', icon: 'chevron-right' },
        { action: 'update', title: 'Update' },
      ],
      title: 'Your data',
      addFooter: false,
    },
    {
      data: [{ action: 'about', title: 'About', icon: 'chevron-right' }],
      title: 'wealthone',
      addFooter: false,
    },
  ];

  const onEditAccount = (item) => {
    navigation.navigate('EditAccount', { account: item });
  };

  const onGenericAction = (action) => {
    switch (action) {
      case 'backup':
        dispatch(backup());
        break;
      case 'restore':
        dispatch(restore());
        break;
      case 'import':
        navigation.navigate('Import');
        break;
      case 'update':
        dispatch(update());
        break;
      case 'about':
        navigation.navigate('About');
        break;
    }
  };

  const onAddAccount = ({ section }) => {
    navigation.navigate('EditAccount', {
      account: {
        id: undefined,
        name: '',
        provider: '',
        isAsset: section.title === 'Assets' ? IsAsset.Asset : IsAsset.Liability,
      },
    });
  };

  return (
    <SafeAreaView style={style.safeAreaView}>
      <AppHeader />
      <SectionList
        style={style.container}
        contentContainerStyle={style.contentContainer}
        renderItem={({ item }) =>
          item.action !== undefined ? (
            <MenuItem
              text={item.title}
              icon={item.icon}
              onClick={() => onGenericAction(item.action)}
            />
          ) : (
            <MenuItem
              text={AccountName(item)}
              icon={'chevron-right'}
              onClick={() => onEditAccount(item)}
            />
          )
        }
        renderSectionHeader={({ section }) => (
          <SectionHeader title={section.title} />
        )}
        renderSectionFooter={(footer) =>
          footer.section.addFooter ? (
            <SectionFooter text="Add" onClick={() => onAddAccount(footer)} />
          ) : null
        }
        stickySectionHeadersEnabled={true}
        keyExtractor={(item, index) => `${index}`}
        sections={sections}
      />
    </SafeAreaView>
  );
};

const mapStateToProps = (state) => {
  const assets = getAssetAccounts(state);
  const liabilities = getLiabilityAccounts(state);
  return { assets, liabilities };
};

export default connect(mapStateToProps)(SettingsScreen);
