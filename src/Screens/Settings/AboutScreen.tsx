import * as React from 'react';
import {
  SafeAreaView,
  SectionList,
  Image,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import {useStyle} from '../../Theme';
import {SectionHeader} from './SectionHeader';

interface IItem {
  readonly type: string;
  readonly value: any;
}

interface IData {
  readonly item: IItem;
}

const AboutScreen = () => {
  const style = useStyle();

  const manifest = {};
  // const { manifest } = Constants;
  const sections = [
    {data: [{value: manifest.sdkVersion}], title: 'sdkVersion'},
    {data: [{value: manifest.privacy}], title: 'privacy'},
    {data: [{value: manifest.version}], title: 'version'},
    {data: [{value: manifest.orientation}], title: 'orientation'},
    {
      data: [{value: manifest.primaryColor, type: 'color'}],
      title: 'primaryColor',
    },
    {
      data: [{value: manifest.splash && manifest.splash.image}],
      title: 'splash.image',
    },
    {
      data: [
        {
          value: manifest.splash && manifest.splash.backgroundColor,
          type: 'color',
        },
      ],
      title: 'splash.backgroundColor',
    },
    {
      data: [
        {
          value: manifest.splash && manifest.splash.resizeMode,
        },
      ],
      title: 'splash.resizeMode',
    },
    {
      data: [
        {
          value: manifest.ios && manifest.ios.supportsTablet ? 'true' : 'false',
        },
      ],
      title: 'ios.supportsTablet',
    },
  ];

  const renderItem = React.useCallback(({item}: IData) => {
    if (item.type === 'color') {
      return (
        <SectionContent>
          {item.value && <Color value={item.value} />}
        </SectionContent>
      );
    } else {
      return (
        <SectionContent>
          <Text style={styles.sectionContentText}>{item.value}</Text>
        </SectionContent>
      );
    }
  }, []);

  return (
    <SafeAreaView style={style.safeAreaView}>
      <SectionList
        style={styles.container}
        renderItem={renderItem}
        renderSectionHeader={({section}) => (
          <SectionHeader title={section.title} />
        )}
        stickySectionHeadersEnabled={true}
        keyExtractor={(item, index) => `${index}`}
        ListHeaderComponent={ListHeader}
        sections={sections}
      />
    </SafeAreaView>
  );
};

const ListHeader = () => {
  // const { manifest } = Constants;
  const manifest: any = {};

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

        <Text style={styles.descriptionText}>{manifest.description}</Text>
      </View>
    </View>
  );
};

const SectionContent = ({children}: React.PropsWithChildren<unknown>) => {
  return <View style={styles.sectionContentContainer}>{children}</View>;
};

interface IAppIconPreviewProps {
  readonly iconUrl?: string;
}
const AppIconPreview = ({iconUrl}: IAppIconPreviewProps) => {
  if (!iconUrl) {
    iconUrl =
      'https://s3.amazonaws.com/exp-brand-assets/ExponentEmptyManifest_192.png';
  }

  return (
    <Image
      source={{uri: iconUrl}}
      style={{width: 64, height: 64}}
      resizeMode="cover"
    />
  );
};

interface IColorProps {
  readonly value?: string;
}
const Color = ({value}: IColorProps) => {
  if (!value) {
    return <View />;
  } else {
    return (
      <View style={styles.colorContainer}>
        <View style={[styles.colorPreview, {backgroundColor: value}]} />
        <View style={styles.colorTextContainer}>
          <Text style={styles.sectionContentText}>{value}</Text>
        </View>
      </View>
    );
  }
};

export const styles = StyleSheet.create({
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

export default AboutScreen;
