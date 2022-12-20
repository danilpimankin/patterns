// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IAccessControl {
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    function getRoleAdmin(bytes32 _role) external view returns(bytes32);

    function grantRole(bytes32 _role, address _account) external;

    function revokeRole(bytes32 _role, address _account) external;

    function renounceRole(bytes32 _role) external;

}

contract AccessControl is IAccessControl{
    struct RoleData {
        mapping(address => bool) member;
        bytes32 adminRole;
        uint countOfMember;
    }

    mapping(bytes32 => RoleData) _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    modifier onlyRole(bytes32 _role) {
        _checkRole(_role);
        _;
    }

    function _checkRole(bytes32 _role) internal view virtual {
       _checkRole(_role, msg.sender);
    } 
    
    function _checkRole(bytes32 _role, address _account) internal view virtual{
        if (!hasRole(_role, _account)) {
            revert("User doesnt have this role");
        }
    }

    function hasRole(bytes32 _role, address _account) internal view virtual returns(bool) {
        return _roles[_role].member[_account];
    }

    function getRoleAdmin(bytes32 _role) public view returns(bytes32){
        return _roles[_role].adminRole;
    }
     
    function grantRole(bytes32 _role, address _account) external virtual onlyRole(getRoleAdmin(_role)) {
        _grantRole(_role, _account);
    }

    function revokeRole(bytes32 _role, address _account) external virtual onlyRole(getRoleAdmin(_role)) {
        _revokeRole(_role, _account);
    }

    function renounceRole(bytes32 _role) external virtual onlyRole(_role) {
        _renounceRole(_role, msg.sender);
    }

    function _setRoleAdmin(bytes32 _role, bytes32 _adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(_role);
        
        _roles[_role].adminRole = _adminRole;

        emit RoleAdminChanged(_role, previousAdminRole, _adminRole);
    }

    function _grantRole(bytes32 _role, address _account) internal {
        if(!hasRole(_role, _account)) {
            _roles[_role].member[_account] = true;
            emit RoleGranted(_role, _account, msg.sender);
        }
    }

    function _revokeRole(bytes32 _role, address _account) internal {
        if(hasRole(_role, _account)) {
            _roles[_role].member[_account] = false;
            emit RoleRevoked(_role, _account, msg.sender);
        }
    }

    function _renounceRole(bytes32 _role, address _account) internal {
        _roles[_role].member[_account] = false;
        emit RoleGranted(_role, _account, msg.sender);
    }



}

