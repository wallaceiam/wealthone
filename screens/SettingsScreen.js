import React from 'react';
import { SafeAreaView, SectionList, Image, StyleSheet, Text, View, ScrollView, TouchableOpacity } from 'react-native';
import FeatherIcon from 'react-native-vector-icons/Feather';

import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import { globalStyles } from './../Style';

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
    const accountSections = [
      { data: (accounts || []).filter(x => x.accountType === AccountTypes.Asset), title: 'Assets' },
      { data: (accounts || []).filter(x => x.accountType === AccountTypes.Liability), title: 'Liabilities' }
    ];

    const settingsSections = [
      {
        data: [
          { action: 'backup', title: 'Backup to iCloud' },
          { action: 'restore', title: 'Restore data' },
          { action: 'export', title: 'Export' },
          { action: 'import', title: 'Import'}
        ], title: 'Your data'
      }
    ];

    const ListHeader = () => {
      // const { manifest } = Constants;
      const manifest = { iconUrl: '', name: '', slug: '', description: ''};

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

        <ScrollView style={styles.container} contentContainerStyle={styles.contentContainer}>

          <SectionList
            style={styles.container}
            renderItem={this._renderItem}
            renderSectionHeader={this._renderSectionHeader}
            renderSectionFooter={this._readerSectionFooter}
            stickySectionHeadersEnabled={true}
            keyExtractor={(item, index) => index}
            sections={accountSections}
          />

          <SectionList
            style={styles.container}
            renderItem={this._renderGenericItem}
            renderSectionHeader={this._renderSectionHeader}
            stickySectionHeadersEnabled={true}
            keyExtractor={(item, index) => index}
            sections={settingsSections}
          />

        </ScrollView>

      </SafeAreaView >
    );
  }

  _renderItem = ({ item }) => {
    return (
      <SectionContent>
        <TouchableOpacity onPress={this.onEditAccount.bind(this, item)}>
          <Text style={styles.sectionContentText}>
            {item.name} - {item.provider}
          </Text>
        </TouchableOpacity>
      </SectionContent>
    );
  };

  _renderGenericItem = ({ item }) => {
    return (
      <SectionContent>
        <TouchableOpacity onPress={this.onGenericAction.bind(this, item.action)}>
          <Text style={styles.sectionContentText}>
            {item.title}
          </Text>
        </TouchableOpacity>
      </SectionContent>
    );
  };

  _renderSectionHeader = ({ section }) => {
    return <SectionHeader title={section.title} />;
  };

  _readerSectionFooter = ({ section }) => {
    return (<SectionContent>
      <TouchableOpacity onPress={this.onAddAccount.bind(this, section)}>
        <Text>Add</Text>
      </TouchableOpacity>
    </SectionContent>);
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

const SectionContent = props => {
  return (
    <View style={styles.sectionContentContainer}>
      {props.children}
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
      source={{ uri: iconUrl }}
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
