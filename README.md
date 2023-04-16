## JSON Validity Checker in Solidity 

I hacked this together quick based on a golang implementation I found on github.  Shout out to https://github.com/Lighfer. 
The purpose of this library is to give all the homies who want to generate their NFT metadata on chain a way to check that 
they are generating valid json.  

### Use this at your own risk.  
I have not audited the original implementation, I tested the code sparingly, and I wrote it quickly late at night. 
Checking if JSON is valid is super gas intensive, so be sure to just use this in tests with foundry or something like that. 
Very long JSON strings will likely cause stack overflow issues.  Welcome to solidity development. 

NOTE: This code does not work with unicode strings.  

### Future Work
If anyone thinks this is useful, I will put in much more effort and make this better. 
Future improvements could include: 

- Returning where the invalidity occurs with a custom error() 
- General code cleanup and gas optimizations 
- Extended unit testing 
- Differential testing 
