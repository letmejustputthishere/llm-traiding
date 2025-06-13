import LLM "mo:llm";
import Prompt "prompt";
import Buffer "mo:base/Buffer";
import Timer "mo:base/Timer";
import Text "mo:base/Text";
import { generatePrompt; performAction } "helpers";

import Swap "swap";

actor {
  let swap = Swap.Swap(10000000000, 0);

  var priceCache : Buffer.Buffer<Float> = Buffer.Buffer<Float>(0);
  var logs : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0);

  ignore Timer.recurringTimer<system>(
    #seconds 6,
    func() : async () {
      // check the amount of ckBTC we can swap for 1 ckUSDC from the mockup implementation
      let currentPrice = await swap.fetchCurrentPrice();
      priceCache.add(currentPrice);
      logs.add("Current price: " # debug_show (currentPrice));
    },
  );

  ignore Timer.recurringTimer<system>(
    #seconds 36,
    func() : async () {

      // prepare the message for the LLM
      let content = generatePrompt(priceCache, swap);

      logs.add("Prompt: \n" # content);

      let response = await LLM.chat(#Llama3_1_8B).withMessages([
        #system_ {
          content = Prompt.SYSTEM_PROMPT;
        },
        #user {
          content;
        },
      ]).send();

      performAction(response, logs, priceCache, swap);

    },
  );

  public func getLogs() : async [Text] {
    Buffer.toArray(logs);
  }

};
