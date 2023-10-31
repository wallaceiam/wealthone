import React, {useEffect} from 'react';
import {SafeAreaView, SectionList} from 'react-native';
import {useNavigation} from '@react-navigation/native';
import {connect} from 'react-redux';
import formatRelative from 'date-fns/formatRelative';

import {useStyle} from '../../Theme';

import {
  backup,
  fetchLastBackupDate,
  restore,
  restorePrevious,
  update,
} from '../../Redux/Actions';
import {IsAsset} from '../../Models/Account';
import {SectionFooter, SectionHeader} from '../../Components';
import MenuItem from './components/MenuItem';
import AppHeader from './components/AppHeader';
import {getAccounts, getLastBackupDate} from '../../Redux/Selectors';
import {IState} from '../../Redux/IState';
import {IAccount} from '../../Redux/IAccount';

interface ISettingsScreenProps {
  readonly assets: IAccount[];
  readonly liabilities: IAccount[];
  readonly lastBackupDate: any;
  readonly dispatch: (action: any) => void;
}

const SettingsScreen = ({
  assets,
  liabilities,
  lastBackupDate,
  dispatch,
}: ISettingsScreenProps) => {
  const navigation = useNavigation();
  const style = useStyle();

  useEffect(() => {
    if (lastBackupDate === undefined) {
      dispatch(fetchLastBackupDate());
    }
  }, [lastBackupDate, dispatch]);

  const lastBackup = lastBackupDate
    ? `Last backup ${formatRelative(new Date(lastBackupDate), new Date())}`
    : '';

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
        {
          action: 'backup',
          title: 'Backup to iCloud',
          icon: 'upload-cloud',
        },
        {
          action: 'restore',
          title: 'Restore data',
          subText: lastBackup,
          icon: 'download-cloud',
        },
        {action: 'export', title: 'Export'},
        {action: 'import', title: 'Import', icon: 'chevron-right'},
        {action: 'update', title: 'Update'},
        {action: 'migrate', title: 'Migrate'},
      ],
      title: 'Your data',
      addFooter: false,
    },
    {
      data: [{action: 'about', title: 'About', icon: 'chevron-right'}],
      title: 'wealthone',
      addFooter: false,
    },
  ];

  const onEditAccount = React.useCallback((item: IAccount) => {
    navigation.navigate('EditAccount', {account: item});
  }, []);

  const onGenericAction = React.useCallback((action: string) => {
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
      case 'migrate':
        dispatch(restorePrevious());
        break;
      case 'about':
        navigation.navigate('About');
        break;
    }
  }, []);

  const onAddAccount = React.useCallback(({section}) => {
    navigation.navigate('EditAccount', {
      account: {
        id: undefined,
        name: '',
        provider: '',
        isAsset: section.title === 'Assets' ? IsAsset.Asset : IsAsset.Liability,
      },
    });
  }, []);

  return (
    <SafeAreaView style={style.safeAreaView}>
      <AppHeader />
      <SectionList
        style={style.container}
        contentContainerStyle={style.contentContainer}
        renderItem={({item}: any) =>
          item.action !== undefined ? (
            <MenuItem
              text={item.title}
              subText={item.subText}
              icon={item.icon}
              onClick={() => onGenericAction(item.action)}
            />
          ) : (
            <MenuItem
              text={item.name}
              subText={item.provider}
              icon={'chevron-right'}
              onClick={() => onEditAccount(item)}
            />
          )
        }
        renderSectionHeader={({section}) => (
          <SectionHeader title={section.title} />
        )}
        renderSectionFooter={footer =>
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

const mapStateToProps = (state: IState) => {
  const accounts = getAccounts(state);
  const assets = (accounts || []).filter(a => a.isAsset === IsAsset.Asset);
  const liabilities = (accounts || []).filter(
    a => a.isAsset === IsAsset.Liability,
  );
  const lastBackupDate = getLastBackupDate(state);
  return {assets, liabilities, lastBackupDate};
};

export default connect(mapStateToProps)(SettingsScreen);
