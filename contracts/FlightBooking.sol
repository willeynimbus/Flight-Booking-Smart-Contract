// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FlightBooking{
    struct Booking{
        address passanger;
        string flightNumber;
        bool isPaid;
        bool isConfirmed;
    }

    mapping (uint => Booking) public bookings;
    uint public bookingCounter;
    uint public totalAvailableTickets;
    uint public ticketPrice;

    address public owner;
    mapping (address=> bool) public authorizedStaff;

    event BookingRequested(uint bookingId, address passanger, string flightNumber);
    event PayamentReceived(uint bookingId);
    event BookingConfirmed(uint bookingId);
    event BookingCancelled(uint bookingId);

    modifier onlyAuthorized(){
        require(authorizedStaff[msg.sender], "Only authorized staff can call this function");
        _;
    }

    constructor(uint _toAvailableTickets, uint _ticketPrice){
        owner = msg.sender;
        authorizedStaff[msg.sender] = true;
        totalAvailableTickets = _toAvailableTickets;
        ticketPrice = _ticketPrice;
    }

    function addAuthorizedStaff(address _staffAddress) external onlyAuthorized{
        authorizedStaff[_staffAddress] = true;
    }

    function requestBooking(string memory _flightNumber) external {
        require(totalAvailableTickets >= 1, "Not enough tickets are avilable to book");

        bookings[bookingCounter] = Booking(
            msg.sender,
            _flightNumber,
            false,
            false
        );

        totalAvailableTickets -= 1;
        emit BookingRequested(bookingCounter, msg.sender, _flightNumber);
        bookingCounter++;
    }

    function makePayment(uint _bookingId) external payable{
        Booking storage booking = bookings[_bookingId];
        require(!booking.isPaid, "Booking already paid");
        require(msg.value==ticketPrice, "Incorrect payment amount.");

        booking.isPaid = true;
        emit PayamentReceived(_bookingId);
    }

    function confirmBooking(uint _bookingId) external onlyAuthorized{
        Booking storage booking = bookings[_bookingId];
        require(booking.isPaid, "Booking must be paid first.");
        require(!booking.isConfirmed, "Booking is already confirmed");

        booking.isConfirmed = true;
        emit BookingConfirmed(_bookingId);
    }

    function cancelBooking(uint _bookingId) external onlyAuthorized {
        Booking storage booking = bookings[_bookingId];
        require(!booking.isConfirmed, "Cannot cancel aconfirmed booking.");
        require(booking.isPaid, "Booking must be paid before cancellation.");

        address payable passanger = payable (booking.passanger);
        uint refundAmount = ticketPrice;
        passanger.transfer(refundAmount);

        totalAvailableTickets += 1;
        booking.isConfirmed = false;
        booking.isPaid = false;

        emit BookingCancelled(_bookingId);
    }

    function addAvailableTickets(uint _numTickets) external onlyAuthorized{
        require(_numTickets > 0, "Number of ticket is grater than zero.");
        totalAvailableTickets += _numTickets;
    }

    function withdrawFunds() external {
        require(msg.sender == owner, "Only the owner can withdraw the funds");
        payable (owner).transfer(address(this).balance);
    }
}