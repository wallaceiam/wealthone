import React from 'react';
import {
  SafeAreaView,
  SectionList,
  Image,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { connect } from 'react-redux';

import { useStyle, useTheme } from '../../Theme';

import { backup, restore, update } from '../../Redux/Actions';
import { IsAsset } from '../../Models/Account';
import { SectionFooter, SectionHeader } from '../../Components';
import Item from './Item';

const AppHeader = () => {
  // const { manifest } = Constants;
  const manifest = {
    name: 'wealthone',
    slug: 'wallace ltd',
    description: 'Your net worth tracker',
  };

  return (
    <View style={styles.titleContainer}>
      <View style={styles.titleIconContainer}>
        <AppIconPreview />
      </View>

      {/* <View style={styles.titleTextContainer}> */}
      <View>
        <Text style={styles.nameText} numberOfLines={1}>
          {manifest.name}
        </Text>

        <Text style={styles.slugText} numberOfLines={1}>
          {manifest.slug}
        </Text>

        <Text style={styles.descriptionText}>{manifest.description}</Text>
      </View>
    </View>
  );
};

const AppIconPreview = () => {
  return (
    <Image
      source={require('../../Assets/appicon.png')}
      style={styles.appIcon}
      resizeMode="cover"
    />
  );
};

const AccountName = ({ name, provider }) => {
  return (
    (name !== '' ? name : '') +
    (provider !== '' && provider !== undefined && provider !== null
      ? ` - ${provider}`
      : '')
  );
};

const SettingsScreen = ({ portfolio, dispatch }) => {
  const navigation = useNavigation();
  const theme = useTheme();
  const style = useStyle();

  const { accounts } = portfolio;
  const sections = [
    {
      data: (accounts || []).filter((x) => x.isAsset === IsAsset.Asset),
      title: 'Assets',
      addFooter: true,
    },
    {
      data: (accounts || []).filter((x) => x.isAsset === IsAsset.Liability),
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

  const SettingsItem = ({ item }) => {
    return item.action !== undefined ? (
      <Item
        text={item.title}
        icon={item.icon}
        onClick={() => onGenericAction(item.action)}
        color={theme.colors.primary}
      />
    ) : (
      <Item
        text={AccountName(item)}
        icon={'chevron-right'}
        onClick={() => onEditAccount(item)}
        color={theme.colors.primary}
      />
    );
  };

  return (
    <SafeAreaView style={style.safeAreaView}>
      <AppHeader />
      <SectionList
        style={style.container}
        contentContainerStyle={style.contentContainer}
        renderItem={(item) => SettingsItem(item)}
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

const styles = StyleSheet.create({
  appIcon: {
    width: 64,
    height: 64,
  },
  titleContainer: {
    paddingHorizontal: 15,
    paddingTop: 15,
    paddingBottom: 15,
    flexDirection: 'row',
  },
  titleIconContainer: {
    marginRight: 15,
    paddingTop: 2,
  },
  nameText: {
    fontWeight: '600',
    fontSize: 18,
  },
  slugText: {
    color: '#a39f9f',
    fontSize: 14,
    backgroundColor: 'transparent',
  },
  descriptionText: {
    fontSize: 14,
    marginTop: 6,
    color: '#4d4d4d',
  },
});

const mapStateToProps = (state) => {
  const { portfolio } = state;
  return { portfolio };
};

export default connect(mapStateToProps)(SettingsScreen);
