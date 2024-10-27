/**
 * Copyright (c) 2024 @Azrun
 * SPDX-License-Identifier: MIT
 */

import { numberOfDecimalDigits } from 'common/math';
import {
  Button,
  Flex,
  NumberInput,
  Section,
  Stack } from 'tgui-core/components';
import { toFixed } from 'tgui-core/math';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

interface StorytellerData {
  path: string;
  name: string;
  description: string;
}

interface QueuedEventData {
  queueID: string;
  category: string;
  name: string;
  time: number;
}

const QueuedEvent = (props: QueuedEventData, key:string) => {
  const { act } = useBackend<EventControllerData>();
  return (
    <Stack align="left">
      <Stack.Item grow>{props.name}</Stack.Item>
      <Stack.Item>{getMinutes(props.time)} Min</Stack.Item>
      <Stack.Item>
        <Button
          icon="delete-left"
          tooltip="Unschedule"
          color="bad"
          onClick={() =>
            act('unschedule_event', {
              name: props.name,
              id: props.queueID,
              category: props.category,
            })
          }
        />
      </Stack.Item>
    </Stack>
  );
};

interface EventData {
  byondRef: string;
  name: string;
  description: string;
  customizable: BooleanLike;
  alwaysCustom: BooleanLike;
  available: BooleanLike;
  enabled: BooleanLike;
}

const getMinutes = (time) => {
  return time / 60 / 10;
};

const toMinutes = (time) => {
  return time * 60 * 10;
};

const getEventIconColor = (enabled, active) => {
  if (enabled) {
    if (active) {
      return 'green';
    } else {
      return 'grey';
    }
  } else {
    return 'red';
  }
};

const Event = (props: EventData) => {
  const { act } = useBackend<EventControllerData>();
  return (
    <Stack>
      <Stack.Item>
        <Button
          icon={'circle'}
          color={getEventIconColor(props.enabled, props.available)}
          onClick={() =>
            act('toggle_event', {
              name: props.name,
              ref: props.byondRef,
            })
          }
        />
      </Stack.Item>
      <Stack.Item>{props.name}</Stack.Item>
      <Stack.Item grow opacity={0.3}>{props.description}</Stack.Item>
      <Stack.Item>
        <Button
          icon="gun"
          tooltip="Fire Event"
          color={props.customizable ? 'green' : 'blue'}
          onClick={() =>
            act('trigger_event', {
              name: props.name,
              ref: props.byondRef,
            })
          }
        />
        <Button
          icon="calendar-plus"
          tooltip="Schedule"
          disabled={props.alwaysCustom}
          onClick={() =>
            act('schedule_event', {
              name: props.name,
              ref: props.byondRef,
            })
          }
        />
      </Stack.Item>
    </Stack>
  );
};

interface EventTypeData {
  name: string;
  enabled: BooleanLike;
  startTime: number;
  delayLow: number;
  delayHigh: number;
  nextEvent: number;
  eventList: Array<EventData>;
}

const EventCategory = (props: EventTypeData) => {
  const { act } = useBackend<EventControllerData>();
  return (
    <Section
      title={
        <Stack align="center">
          <Stack.Item>{props.name}</Stack.Item>
          <Stack.Item>
            <Button.Checkbox
              checked={props.enabled}
              tooltip="Toggle Event Enablement"
            />
          </Stack.Item>
        </Stack>
      }
    >
      {props.startTime ? (
        <Flex>
          <Flex.Item mb={1}>
            <Stack>
              <Stack.Item>
                Start Time:
                <NumberInput
                  value={getMinutes(props.startTime)}
                  minValue={0}
                  maxValue={500}
                  stepPixelSize={4}
                  step={0.1}
                  width="50px"
                  format={(value) => toFixed(value, numberOfDecimalDigits(0.1))}
                  unit="Min"
                  onDrag={(value) =>
                    act('set_category_value', {
                      name: 'startTime',
                      category: props.name,
                      new_data: toMinutes(value),
                    })
                  }
                />
              </Stack.Item>
              <Stack.Item>
                Time Between Events:{' '}
                <NumberInput
                  value={getMinutes(props.delayLow)}
                  minValue={0}
                  maxValue={500}
                  stepPixelSize={4}
                  step={0.1}
                  width="50px"
                  format={(value) => toFixed(value, numberOfDecimalDigits(0.1))}
                  unit="Min"
                  onDrag={(value) =>
                    act('set_category_value', {
                      name: 'delayLow',
                      category: props.name,
                      new_data: toMinutes(value),
                    })
                  }
                />
                /{' '}
                <NumberInput
                  value={getMinutes(props.delayHigh)}
                  minValue={0}
                  maxValue={500}
                  stepPixelSize={4}
                  step={0.1}
                  width="50px"
                  format={(value) => toFixed(value, numberOfDecimalDigits(0.1))}
                  unit="Min"
                  onDrag={(value) =>
                    act('set_category_value', {
                      name: 'delayHigh',
                      category: props.name,
                      new_data: toMinutes(value),
                    })
                  }
                />
              </Stack.Item>
            </Stack>
          </Flex.Item>
        </Flex>
      ) : (
        ''
      )}
      <Flex direction="column">
        {props.eventList ? (
          props.eventList.map((event) => (
            <Flex.Item key={event.name}
            >
              <Event {...event} />
            </Flex.Item>
          ))
        ) : (
          <Flex.Item />
        )}
      </Flex>
    </Section>
  );
};

interface EventControllerData {
  eventsEnabled: BooleanLike;
  announce: BooleanLike;

  minPopulation: number;
  aliveAntagonistThreshold: number;
  deadPlayersThreshold: number;
  eventData: Array<EventTypeData>;
  queuedEvents: Array<QueuedEventData>;
  storyTellerList: Array<StorytellerData>;
}

export const EventController = () => {
  const { act, data } = useBackend<EventControllerData>();

  return (
    <Window width={600} height={600}>
      <Window.Content scrollable>
        <Section
          title={
            <Stack align="center">
              <Stack.Item>Event Controller:</Stack.Item>
              <Stack.Item>
                <Button.Checkbox
                  checked={data.eventsEnabled}
                  tooltip="Toggle Event Enablement"
                  onClick={() =>
                    act('set_value', {
                      name: 'eventsEnabled',
                      new_data: !data.eventsEnabled,
                    })
                  }
                >
                  Events Enabled
                </Button.Checkbox>
              </Stack.Item>
              <Stack.Item>
                <Button.Checkbox
                  checked={data.announce}
                  tooltip="Toggle Event Announcements"
                  onClick={() =>
                    act('set_value', {
                      name: 'announce',
                      new_data: !data.announce,
                    })
                  }
                >
                  Announce Events
                </Button.Checkbox>
              </Stack.Item>
            </Stack>
          }
        >
          <Stack>
            <Stack.Item>
              Minimum Population:{' '}
              <NumberInput
                value={data.minPopulation}
                minValue={0}
                maxValue={100}
                stepPixelSize={4}
                step={1}
                width="30px"
                onDrag={(value) =>
                  act('set_value', {
                    name: 'minPopulation',
                    new_data: {
                      value,
                    },
                  })
                }
              />
            </Stack.Item>
            <Stack.Item>
              Alive Antagonist Threshold:{' '}
              <NumberInput
                value={data.aliveAntagonistThreshold}
                minValue={0}
                maxValue={1}
                stepPixelSize={4}
                step={0.01}
                width="40px"
                onDrag={(value) =>
                  act('set_value', {
                    name: 'aliveAntagonistThreshold',
                    new_data: {
                      value,
                    },
                  })
                }
              />
            </Stack.Item>
            <Stack.Item>
              Dead Player Threshold:{' '}
              <NumberInput
                value={data.deadPlayersThreshold}
                minValue={0}
                maxValue={1}
                stepPixelSize={4}
                step={0.01}
                width="40px"
                onDrag={(value) =>
                  act('set_value', {
                    name: 'deadPlayersThreshold',
                    new_data: {
                      value,
                    },
                  })
                }
              />
            </Stack.Item>
          </Stack>
        </Section>
        <Section title="Scheduled Events">
          <Flex direction="column">
            {data.queuedEvents.length ? (
              data.queuedEvents.map((queuedEvent) => (
                <Flex.Item
                  mb={1}
                  key={queuedEvent.name}
                  >
                  <QueuedEvent {...queuedEvent} />
                </Flex.Item>
              ))
            ) : (
              <Flex.Item>None</Flex.Item>
            )}
          </Flex>
          {}
        </Section>

        <Flex direction="column">
          {data.eventData.map((eventCat) => (
            <Flex.Item mb={1} key={eventCat.name}>
              <EventCategory {...eventCat} />
            </Flex.Item>
          ))}
        </Flex>
        <Section fontSize={1.5}>
          <Button>Push</Button>
        </Section>
      </Window.Content>
    </Window>
  );
};
