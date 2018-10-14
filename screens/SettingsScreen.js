import React from 'react';
import { SafeAreaView, SectionList, Image, StyleSheet, Text, View, ScrollView, TouchableOpacity } from 'react-native';
import FeatherIcon from 'react-native-vector-icons/Feather';

import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import { globalStyles } from './../Style';
import { globalColours } from './../Colours';

import { backup, restore } from './../redux/Actions';
import { AccountTypes } from '../models/Account';

class SettingsScreen extends React.Component {
  static navigationOptions = ({ navigate, navigation }) => ({
    title: 'Settings',
    headerBackTitleVisible: false,
    headerBackTitle: null
  });

  render() {
    // const { manifest } = Constants;
    const { accounts } = this.props.portfolio;
    const sections = [
      { data: (accounts || []).filter(x => x.accountType === AccountTypes.Asset), title: 'Assets', addFooter: true },
      { data: (accounts || []).filter(x => x.accountType === AccountTypes.Liability), title: 'Liabilities', addFooter: true },
      {
        data: [
          { action: 'backup', title: 'Backup to iCloud', icon: 'upload-cloud' },
          { action: 'restore', title: 'Restore data', icon: 'download-cloud' },
          { action: 'export', title: 'Export' },
          { action: 'import', title: 'Import' }
        ], title: 'Your data', addFooter: false
      }
    ];

    const ListHeader = () => {
      // const { manifest } = Constants;
      const manifest = { iconUrl: require('./../assets/appicon.png'), name: 'wealthone', slug: 'wallace ltd', description: 'Your net worth tracker' };

      return (
        <View style={styles.titleContainer}>
          <View style={styles.titleIconContainer}>
            <AppIconPreview iconUrl={manifest.iconUrl} />
          </View>

          <View style={styles.titleTextContainer}>
            <Text style={styles.nameText} numberOfLines={1}>
              {manifest.name}
            </Text>

            <Text style={styles.slugText} numberOfLines={1}>
              {manifest.slug}
            </Text>

            <Text style={styles.descriptionText}>
              {manifest.description}
            </Text>
          </View>
        </View>
      );
    };

    return (
      <SafeAreaView style={globalStyles.safeAreaView}>

        <ListHeader />

        <ScrollView style={globalStyles.container} contentContainerStyle={globalStyles.contentContainer}>

          <SectionList
            style={globalStyles.container}
            renderItem={this._renderItem}
            renderSectionHeader={({ section }) => <Text style={globalStyles.sectionHeaderStyle}> {section.title} </Text>}
            renderSectionFooter={this._readerSectionFooter}
            stickySectionHeadersEnabled={true}
            keyExtractor={(item, index) => index}
            sections={sections}
          />

        </ScrollView>

      </SafeAreaView >
    );
  }

  renderAccountName = ({ name, provider }) => {
    return (name !== '' ? name : '') +
      (provider !== '' && provider !== undefined && provider !== null ? ` - ${provider}` : '');
  }

  _renderItem = ({ item }) => {

    return item.action !== undefined ?
      (
        <TouchableOpacity onPress={this.onGenericAction.bind(this, item.action)}>
          <View style={globalStyles.row}>
            <Text style={globalStyles.bottomMargin}>
              {item.title}
            </Text>
            {
              item.icon !== undefined ? (<FeatherIcon name={item.icon} color={globalColours.primary} />) : null
            }
          </View>
        </TouchableOpacity>
      ) : (
        <TouchableOpacity onPress={this.onEditAccount.bind(this, item)}>
          <View style={globalStyles.row}>
            <Text style={globalStyles.bottomMargin}>
              {this.renderAccountName(item)}
            </Text>
            <FeatherIcon name="chevron-right" color={globalColours.primary} />
          </View>
        </TouchableOpacity>
      );
  };

  _renderSectionHeader = ({ section }) => {
    return <SectionHeader title={section.title} />;
  };

  _readerSectionFooter = ({ section }) => {
    return section.addFooter ? (
      <TouchableOpacity onPress={this.onAddAccount.bind(this, section)}>
        <View style={globalStyles.row}>
          <Text style={globalStyles.bottomMargin}>Add</Text>
          <FeatherIcon name="plus" color={globalColours.primary} />
        </View>
      </TouchableOpacity>) : null;
  }

  onAddAccount = (item) => {
    if (item.title === 'Assets') {
      this.props.navigation.navigate('EditAccount', { account: { id: undefined, name: '', provider: '', accountType: AccountTypes.Asset } });
    } else {
      this.props.navigation.navigate('EditAccount', { account: { id: undefined, name: '', provider: '', accountType: AccountTypes.Liability } });
    }
  }

  onEditAccount = (item) => {
    this.props.navigation.navigate('EditAccount', { account: item });
  }

  onGenericAction = (action) => {
    switch (action) {
      case 'backup':
        this.props.backup();
        break;
      case 'restore':
        this.props.restore();
        break;
      case 'import':
        this.props.navigation.navigate('Import');
        break;
    }
  }
}

const SectionHeader = ({ title }) => {
  return (
    <View style={styles.sectionHeaderContainer}>
      <Text style={styles.sectionHeaderText}>
        {title}
      </Text>
    </View>
  );
};

const AppIconPreview = ({ iconUrl }) => {
  if (!iconUrl) {
    iconUrl =
      'https://s3.amazonaws.com/exp-brand-assets/ExponentEmptyManifest_192.png';
  }

  return (
    <Image
      source={require('./../assets/appicon.png')}
      style={{ width: 64, height: 64 }}
      resizeMode="cover"
    />
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
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
  sectionHeaderContainer: {
    backgroundColor: '#fbfbfb',
    paddingVertical: 8,
    paddingHorizontal: 15,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: '#ededed',
  },
  sectionHeaderText: {
    fontSize: 14,
  },
  sectionContentContainer: {
    paddingTop: 8,
    paddingBottom: 12,
    paddingHorizontal: 15,
  },
  sectionContentText: {
    color: '#808080',
    fontSize: 14,
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
  colorContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  colorPreview: {
    width: 17,
    height: 17,
    borderRadius: 2,
    marginRight: 6,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: '#ccc',
  },
  colorTextContainer: {
    flex: 1,
  },
});

const mapStateToProps = (state) => {
  const { portfolio } = state
  return { portfolio }
};

const mapDispatchToProps = dispatch => (
  bindActionCreators({
    backup,
    restore,
  }, dispatch)
);

export default connect(mapStateToProps, mapDispatchToProps)(SettingsScreen);
