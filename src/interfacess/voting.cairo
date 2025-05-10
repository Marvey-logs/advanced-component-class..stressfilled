use starknet::ContractAddress;
use starknet::*;

#[starknet::interface]
pub trait Ivote<TContractState> {
    fn create_poll(ref self: TContractState, name: ByteArray, desc: ByteArray) -> u256;
    fn vote(ref self: TContractState, support: bool, id:u256);
    fn resolve_poll(ref self: TContractState, id: u256);
    fn get_poll(self: @TContractState, id: u256);
}

#[derive(Drop, Clone, Default, Serde, PartialEq, starknet::Store)]
pub struct Poll {
    pub name: ByteArray,
    pub desc: ByteArray,
    pub yes_votes: u256,
    pub no_votes: u256,
    pub status: Pollstatus,
}

#[generate_trait]
pub impl PollImpl of PollTrait {
    fn resolve(self: Poll) {
        assert(self.yes_votes + self.no_votes >= DEFAULT_THREASHOLD, 'COULD NOT RESOLVE')
        let mut status = false;
        if self.yes_votes > self.no_votes{
            status = true;
        }
    }
}

#[derive(Drop, Copy, Default, Serde, PartialEq, starknet::Store)]
pub enum Pollstatus {
    #[default]
    pending,
    finished,
}
#[derive(Drop, starknet::Event)]
pub struct voted {
    #[key]
    pub id: u256,
    #[key]
    pub voter: ContractAddress, 
}

pub const DEFAULT_THREASHOLD: u256 = 10;
