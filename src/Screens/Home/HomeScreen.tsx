import {useNavigation} from '@react-navigation/native';
import React, {useCallback, useLayoutEffect} from 'react';
import {SafeAreaView, TouchableOpacity} from 'react-native';

import {justDate, toUtc} from '../../Redux/DateHelpers';
import {useStyle} from '../../Theme';
import PlusIcon from '../../Components/Icons/PlusIcon';
import PortfolioList from './components/PortfolioList2';

const HomeScreen = () => {
  const navigation = useNavigation();
  const style = useStyle();

  const onNavToEntry = useCallback(() => {
    navigation.navigate('HomeEntry', {
      date: toUtc(justDate(new Date())).getTime(),
    });
  }, [navigation]);

  useLayoutEffect(() => {
    navigation.setOptions({
      title: null,
      headerRight: () => (
        <TouchableOpacity
          style={style.rightMargin}
          onPress={() => onNavToEntry()}>
          <PlusIcon size={24} />
        </TouchableOpacity>
      ),
    });
  }, [navigation, onNavToEntry, style.rightMargin]);

  return (
    <SafeAreaView style={style.safeAreaView}>
      <PortfolioList />
    </SafeAreaView>
  );
};

export default HomeScreen;
