<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->
<a name="readme-top"></a>
<!--
*** Thanks for checking out the Best-README-Template. If you have a suggestion
*** that would make this better, please fork the repo and create a pull request
*** or simply open an issue with the tag "enhancement".
*** Don't forget to give the project a star!
*** Thanks again! Now go create something AMAZING! :D
-->



<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->




<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://www.agrf.org.au">
    <img src="logos/logo.png" alt="Logo" width="100" height="100">
  </a>
  &nbsp;
  <a href="https://www.pacb.com">
    <img src="logos/pacbio-logo.PNG" alt="Logo" width="140" height="80">
  </a>
</div>

<h3 align="center">An AGRF repository for manipulating, assembling and analysis HiFi data in AWS</h3>

<!-- GETTING STARTED -->

## <h3 align="center">Getting Started</h3>

Simply pull this repository into the AWS instance to have the most up-to-date copies of the scripts available. The AWS Instances are maintained through AMI's separately, and should always be compatible (and work out of the box).

### <h3 align="center">Prerequisites</h3>

Due to compatability issues, there are two separate AMIs to have running depending on what kind of work you intend on running. 

If you want to run assemblies, demultiplexing, or BAM conversions, you will need to start an instance using the following AMI:
  ```
  PacBio Tools Image
  ```
If you want to run the 16S workflow, or any future Nextflow workflow, you will need to start an instance using the following AMI:
  ```
  16S Nextflow 1Tb attached
  ```

Take note that your username will be different - The Pacbio tools image uses 'ubuntu', whereas the nextflow image uses 'ec2-user'. Keep that in mind when connecting with Putty/Filezilla/etc.

### <h3 align="center">Installation</h3>

1. Turn on and log into AMI as per the SOP.

2. Clone the repo into the home directory (/home/ubuntu/ or /home/ec2-user/). If you do this immediately after logging into the instance, you'll already be here.

   ```sh
   git clone https://github.com/roylejw/PacBio-related-scripts.git
   ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- USAGE EXAMPLES -->
## <h3 align="center">Usage</h3>

  ```sh
  to do
  ```
<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- CONTACT -->
## <h3 align="center">Contact</h3>

Jack Royle <br />
Twitter - [@Royleity](https://twitter.com/Royleity)  <br />
Email: jack.royle@agrf.org.au   <br />    [![LinkedIn][linkedin-shield]][linkedin-url]

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/github_username/repo_name.svg?style=for-the-badge
[contributors-url]: https://github.com/github_username/repo_name/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/github_username/repo_name.svg?style=for-the-badge
[forks-url]: https://github.com/github_username/repo_name/network/members
[stars-shield]: https://img.shields.io/github/stars/github_username/repo_name.svg?style=for-the-badge
[stars-url]: https://github.com/github_username/repo_name/stargazers
[issues-shield]: https://img.shields.io/github/issues/github_username/repo_name.svg?style=for-the-badge
[issues-url]: https://github.com/github_username/repo_name/issues
[license-shield]: https://img.shields.io/github/license/github_username/repo_name.svg?style=for-the-badge
[license-url]: https://github.com/github_username/repo_name/blob/master/LICENSE.txt
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/jackroyle1
[product-screenshot]: images/screenshot.png
[Next.js]: https://img.shields.io/badge/next.js-000000?style=for-the-badge&logo=nextdotjs&logoColor=white
[Next-url]: https://nextjs.org/
[React.js]: https://img.shields.io/badge/React-20232A?style=for-the-badge&logo=react&logoColor=61DAFB
[React-url]: https://reactjs.org/
[Vue.js]: https://img.shields.io/badge/Vue.js-35495E?style=for-the-badge&logo=vuedotjs&logoColor=4FC08D
[Vue-url]: https://vuejs.org/
[Angular.io]: https://img.shields.io/badge/Angular-DD0031?style=for-the-badge&logo=angular&logoColor=white
[Angular-url]: https://angular.io/
[Svelte.dev]: https://img.shields.io/badge/Svelte-4A4A55?style=for-the-badge&logo=svelte&logoColor=FF3E00
[Svelte-url]: https://svelte.dev/
[Laravel.com]: https://img.shields.io/badge/Laravel-FF2D20?style=for-the-badge&logo=laravel&logoColor=white
[Laravel-url]: https://laravel.com
[Bootstrap.com]: https://img.shields.io/badge/Bootstrap-563D7C?style=for-the-badge&logo=bootstrap&logoColor=white
[Bootstrap-url]: https://getbootstrap.com
[JQuery.com]: https://img.shields.io/badge/jQuery-0769AD?style=for-the-badge&logo=jquery&logoColor=white
[JQuery-url]: https://jquery.com 
