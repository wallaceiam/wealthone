import React, { useLayoutEffect, useState } from 'react';
import {
  SafeAreaView,
  View,
  Text,
  SectionList,
  TouchableOpacity,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import Slider from '@react-native-community/slider';

import { connect } from 'react-redux';

import { saveGoal } from '../../Redux/Actions';

import { useStyle, useTheme } from '../../Theme';
import SectionHeader from '../../Components/SectionHeader';
import SaveIcon from '../../Components/Icons/SaveIcon';

const EditGoalScreen = ({ input, dispatch }) => {
  const navigation = useNavigation();
  const theme = useTheme();
  const style = useStyle();

  const [currentAge, setCurrentAge] = useState(input.currentAge || 40);
  const [retirementAge, setRetirementAge] = useState(input.retirementAge || 68);
  const [earnings, setEarnings] = useState(input.earnings || 55000);
  const [contributions, setContributions] = useState(
    input.contributions || 1700,
  );
  const [pension, setPension] = useState(input.pension || 0);
  const [investmentStyle, setInvestmentStyle] = useState(input.investment || 3);
  const [lifeStyle, setLifeStyle] = useState(input.lifestyle || 40);

  const onSaveGoal = () => {
    dispatch(
      saveGoal({
        currentAge,
        retirementAge,
        earnings,
        contributions,
        pension,
        investment: investmentStyle,
        lifestyle: lifeStyle,
      }),
    );
    navigation.goBack();
  };

  useLayoutEffect(() => {
    navigation.setOptions({
      title: 'Edit Goal',
      headerRight: () => (
        <TouchableOpacity
          style={style.rightMargin}
          onPress={() => onSaveGoal()}>
          <SaveIcon />
        </TouchableOpacity>
      ),
    });
  }, [navigation, onSaveGoal]);

  const titleForItem = (item) => {
    switch (item) {
      case 'age':
        return 'Current age:';
      case 'retirementAge':
        return 'Retirement age:';
      case 'salary':
        return 'Annual salary';
      case 'contributions':
        return 'Montly contributions';
      case 'investmentStyle':
        return 'Investment style';
      case 'pension':
        return 'Pension';
      case 'retirementLifeStyle':
        return 'Life style';
    }
    return null;
  };

  const sliderForItem = (item) => {
    switch (item) {
      case 'age':
        return (
          <Slider
            step={1}
            minimumValue={18}
            maximumValue={retirementAge}
            minimumTrackTintColor={theme.colors.primary}
            onValueChange={(v) => setCurrentAge(Math.min(v, retirementAge))}
            value={currentAge}
          />
        );
      case 'retirementAge':
        return (
          <Slider
            step={1}
            minimumValue={currentAge}
            maximumValue={75}
            minimumTrackTintColor={theme.colors.primary}
            onValueChange={(v) => setRetirementAge(Math.max(v, currentAge))}
            value={retirementAge}
          />
        );
      case 'salary':
        return (
          <Slider
            step={100}
            minimumValue={0}
            maximumValue={150000}
            minimumTrackTintColor={theme.colors.primary}
            onValueChange={(v) => setEarnings(v)}
            value={earnings}
          />
        );
      case 'contributions':
        return (
          <Slider
            step={50}
            minimumValue={0}
            maximumValue={5000}
            minimumTrackTintColor={theme.colors.primary}
            onValueChange={(v) => setContributions(v)}
            value={contributions}
          />
        );
      case 'investmentStyle':
        return (
          <Slider
            step={1}
            minimumValue={0}
            maximumValue={6}
            minimumTrackTintColor={theme.colors.primary}
            onValueChange={(v) => setInvestmentStyle(v)}
            value={investmentStyle}
          />
        );
      case 'retirementLifeStyle':
        return (
          <Slider
            step={1}
            minimumValue={0}
            maximumValue={100}
            minimumTrackTintColor={theme.colors.primary}
            onValueChange={(v) => setLifeStyle(v)}
            value={lifeStyle}
          />
        );
    }
    return null;
  };

  const valueForItem = (item) => {
    const currencyFormatter = (v) => v;
    //Globalize.getCurrencyFormatter('GBP', {
    // minimumFractionDigits: 0, maximumFractionDigits: 0 });

    switch (item) {
      case 'age':
        return <Text style={style.text}>{currentAge}</Text>;
      case 'retirementAge':
        return <Text style={style.text}>{retirementAge}</Text>;
      case 'salary':
        return <Text style={style.text}>{currencyFormatter(earnings)}/y</Text>;
      case 'contributions':
        return (
          <Text style={style.text}>{currencyFormatter(contributions)}/m</Text>
        );
      case 'investmentStyle': {
        switch (investmentStyle) {
          case 0:
            return <Text style={style.text}>Safety first</Text>;
          case 1:
            return <Text style={style.text}>Defensive</Text>;
          case 2:
            return <Text style={style.text}>Cautious</Text>;
          case 3:
            return <Text style={style.text}>Slightly cautious</Text>;
          case 4:
            return <Text style={style.text}>Moderate</Text>;
          case 5:
            return <Text style={style.text}>Adventurous</Text>;
          case 6:
            return <Text style={style.text}>Very adventurous</Text>;
        }
        return null;
      }
      case 'pension':
        return null;
      case 'retirementLifeStyle':
        return <Text style={style.text}>{lifeStyle}%</Text>;
    }
    return null;
  };

  const renderItem = ({ item }) => {
    const title = titleForItem(item);
    const slider = sliderForItem(item);
    const val = valueForItem(item);
    return (
      <View style={[style.column, style.bottomMargin]}>
        <View style={[style.row, style.noMargins]}>
          <Text style={style.text}>{title} </Text>
          {val}
        </View>
        <View style={{ flex: 2 }}>{slider}</View>
      </View>
    );
  };

  const sections = [
    { title: 'Time', data: ['age', 'retirementAge'] },
    {
      title: 'Money',
      data: ['salary', 'contributions', 'retirementLifeStyle'],
    },
    { title: 'Settings', data: ['investmentStyle', 'pension'] },
  ];
  return (
    <SafeAreaView style={style.safeAreaView}>
      <View style={style.container}>
        <SectionList
          style={style.contentContainer}
          sections={sections}
          renderSectionHeader={({ section }) => (
            <SectionHeader title={section.title} />
          )}
          renderItem={renderItem}
          keyExtractor={(item, index) => `${index}`}
        />
      </View>
    </SafeAreaView>
  );
};

const mapStateToProps = (state) => {
  const { portfolio } = state;
  const { goal } = portfolio;
  const { input } = goal || { input: {} };

  return { input };
};

export default connect(mapStateToProps)(EditGoalScreen);
