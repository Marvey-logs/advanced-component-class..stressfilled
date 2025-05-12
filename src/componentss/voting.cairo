#[starknet::component]
pub mod VotingComponent {

    use crate::interfacess::voting::PollTrait;
use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map};
    use crate::interfacess::voting::*;


    #[storage]
    pub struct Storage{
        poll: Map<u256, Poll>,
        voters: Map<(ContractAddress, u256), bool>,
        nonce: u256
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        voted: voted
    }

    #[embeddable_as(VotingImpl)]
    pub impl  voting<TContractState, +HasComponent<TContractState>> of Ivote<ComponentState<TContractState>> {
        fn create_poll(ref self: ComponentState<TContractState>, name: ByteArray, desc: ByteArray,) -> u256 {
            let id = self.nonce.read() +1;
            assert!(name != "" && desc != "", "NAME OR DESC IS EMPTY");
            let mut poll: Poll = Default::default();
            poll.name = name;
            poll.desc = desc;
            self.poll.entry(id).write(poll);
            self.nonce.write(id);
            id
        }
        fn vote(ref self: ComponentState<TContractState>, support: bool, id: u256){
            
            let mut poll = self.poll.entry(id).read();
            assert(poll != Default::default(), 'INVALID POLL');
            assert(poll.status == Default::default(), 'POLL HAS ENDED');
            let caller = get_caller_address();
            let has_voted =  self.voters.entry((caller, id)).read();
            assert(!has_voted, 'YOU VOTE ONLY ONCE');


            match support {
                true => poll.yes_votes += 1,
                _ => poll.no_votes += 1
            };

            let vote_count = poll.yes_votes + poll.no_votes;
            if vote_count >= DEFAULT_THREASHOLD {
                poll.resolve();
                
            }
            self.poll.entry(id).write(poll);
            self.voters.entry((caller, id)).write(true);
            self.emit(voted {id, voter: caller});
        }
        fn resolve_poll(ref self: ComponentState<TContractState>, id: u256){

        }
        fn get_poll(self: @ComponentState<TContractState>, id: u256){
            self.poll.entry(id).read();
        }
    }
        

    #[generate_trait]
    pub impl  VoteInternalImpl<TContractState, +HasComponent<ComponentState<TContractState>>,>  of VoteTrait<TContractState> {
        fn resolve_poll(ref self: ComponentState<TContractState>, poll: Poll){}
        
    }
}