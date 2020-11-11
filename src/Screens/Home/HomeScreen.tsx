import { useNavigation } from '@react-navigation/native';
import React, { useCallback, useLayoutEffect } from 'react';
import { SafeAreaView, ScrollView, TouchableOpacity } from 'react-native';

import { justDate, toUtc } from '../../Redux/DateHelpers';
import { useStyle } from '../../Theme';
import PlusIcon from '../../Components/Icons/PlusIcon';
import HomeTopBar from './components/HomeTopBar';
import NetworthGrowthChart from './components/NetworthGrowthChart';
import PortfolioList from './components/PortfolioList';

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
      <ScrollView
        style={style.container}
        contentContainerStyle={style.contentContainer}>
        <HomeTopBar />
        <NetworthGrowthChart />
        <PortfolioList />
      </ScrollView>
    </SafeAreaView>
  );
};

export default HomeScreen;
