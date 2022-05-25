// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";

import "./IWRLD_Name_Service_Metadata.sol";

contract WRLD_Name_Service_Metadata is IWRLD_Name_Service_Metadata {
    function getMetadata(string memory _name, uint256 _expiresAt) external pure override returns (string memory) {
      string memory image = getImage(_name, _expiresAt);

      return string(
        abi.encodePacked(
          '{"name":"',
          _name,
          '", "expiresAt":"',
          Strings.toString(_expiresAt),
          '", "image": "',
          image,
          '"}'
        ));
    }

    function getImage(string memory _name, uint256 _expiresAt) public pure override returns (string memory) {
      return string(abi.encodePacked('<svg width="270" height="270" viewBox="0 0 270 270" fill="none" xmlns="http://www.w3.org/2000/svg"><rect width="270" height="270" fill="url(#paint0_linear)"/><defs><filter id="dropShadow" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse" height="270" width="270"><feDropShadow dx="0" dy="1" stdDeviation="2" flood-opacity="0.225" width="200%" height="200%"/></filter></defs><path d="M38.0397 51.0875C38.5012 52.0841 39.6435 54.0541 39.6435 54.0541L52.8484 32L39.9608 41.0921C39.1928 41.6096 38.5628 42.3102 38.1263 43.1319C37.5393 44.3716 37.2274 45.7259 37.2125 47.1C37.1975 48.4742 37.4799 49.8351 38.0397 51.0875Z" fill="white" filter="url(#dropShadow)"/><path d="M32.152 59.1672C32.3024 61.2771 32.9122 63.3312 33.9405 65.1919C34.9689 67.0527 36.3921 68.6772 38.1147 69.9567L52.8487 80C52.8487 80 43.6303 67.013 35.8549 54.0902C35.0677 52.7249 34.5385 51.2322 34.2926 49.6835C34.1838 48.9822 34.1838 48.2689 34.2926 47.5676C34.0899 47.9348 33.6964 48.6867 33.6964 48.6867C32.908 50.2586 32.371 51.9394 32.1043 53.6705C31.9508 55.5004 31.9668 57.3401 32.152 59.1672Z" fill="white" filter="url(#dropShadow)"/><path d="M70.1927 60.9125C69.6928 59.9159 68.4555 57.946 68.4555 57.946L54.1514 80L68.1118 70.9138C68.9436 70.3962 69.6261 69.6956 70.099 68.8739C70.7358 67.6334 71.0741 66.2781 71.0903 64.9029C71.1065 63.5277 70.8001 62.1657 70.1927 60.9125Z" fill="white" filter="url(#dropShadow)"/><path d="M74.8512 52.8328C74.7008 50.7229 74.0909 48.6688 73.0624 46.8081C72.0339 44.9473 70.6105 43.3228 68.8876 42.0433L54.1514 32C54.1514 32 63.3652 44.987 71.1478 57.9098C71.933 59.2755 72.4603 60.7682 72.7043 62.3165C72.8132 63.0178 72.8132 63.7311 72.7043 64.4324C72.9071 64.0652 73.3007 63.3133 73.3007 63.3133C74.0892 61.7414 74.6262 60.0606 74.893 58.3295C75.0485 56.4998 75.0345 54.66 74.8512 52.8328Z" fill="white" filter="url(#dropShadow)"/><text x="32.5" y="150" font-size="30px" fill="white" filter="url(#dropShadow)">',
        _name,
        '</text><text id="timeText" x="160" y="240" font-size="14px" fill="white" filter="url(#dropShadow)">',
        Strings.toString(_expiresAt),
        '</text><defs><style>text{font-family:Plus Jakarta Sans,DejaVu Sans,Noto Color Emoji,Apple Color Emoji,sans-serif;font-style:normal;font-variant-numeric:tabular-nums;font-weight:700;line-height:34px}</style><linearGradient id="paint0_linear" x1="190.5" y1="302" x2="-64" y2="-172.5" gradientUnits="userSpaceOnUse"><stop stop-color="#44BCF0"/><stop offset="0.428185" stop-color="#628BF3"/><stop offset="1" stop-color="#A099FF"/></linearGradient><linearGradient id="paint1_linear" x1="0" y1="0" x2="269.553" y2="285.527" gradientUnits="userSpaceOnUse"><stop stop-color="#EB9E9E"/><stop offset="1" stop-color="#992222"/></linearGradient></defs><script><![CDATA[ function formatDate (value, hide_second){ if(!value){return null;} if ("object" == typeof value){try { return getDateTimeString(value, hide_second)}catch(e){}} let n = parseInt(value); if (n < 9999999999){n *= 1000;} let ot = new Date().getTimezoneOffset(); n += ot * 60 * 1000; let date = new Date(n); return getDateTimeString(date, hide_second) } function getDateTimeString(date, hide_second){ let y = date.getFullYear(); let MM = date.getMonth() + 1; MM = MM < 10 ? ("0" + MM) : MM; let d = date.getDate(); d = d < 10 ? ("0" + d) : d; return y + "-" + MM + "-" + d; } let ts = document.getElementById("timeText"); document.getElementById("timeText").innerHTML = formatDate(ts.innerHTML);]]></script></svg>'
        ));
    }

  function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
    return interfaceId == type(IWRLD_Name_Service_Metadata).interfaceId;
  }
}
